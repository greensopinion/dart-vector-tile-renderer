# GPU Renderer Performance Notes

This file records the GPU renderer baseline and the follow-up work aimed at
making pan and zoom smoother. It is intentionally separate from the regular
package README so profiling decisions have one source of truth.

## Committed Baseline

The baseline is commit `1763352` (`feat: port GPU tile renderer to
flutter_scene 0.18.1 / new flutter_gpu`). It was already on branch
`pb/flutter-scene-0.18-master-gpu` before the performance follow-up.

It contains the Flutter master GPU migration and fixes required for correct
map rendering on the new API:

- Updates `flutter_scene`, `flutter_gpu_shaders`, native build hooks, shader
  loading, GPU buffer binding, material lighting, and camera APIs.
- Loads the tile shader library asynchronously and prevents renderer use until
  the scene and shaders are ready.
- Restores deterministic 2D layer order with per-layer depth offsets, depth
  testing/writes, and no face culling. This prevents the renderer's pipeline
  sorting from changing map paint order.
- Treats translucent colored material as non-opaque, preventing it from
  incorrectly covering layers below it.
- Fixes text visibility and scale after the new reflected vertex layout. Text
  is scaled by device display scale, with stable SDF softness.
- Adds process-wide `GpuMapSettings` for anti-aliasing and experimental
  frustum culling. Anti-aliasing is a quality/per-frame-GPU-cost tradeoff.

Together with the smoothing work below, this commit provides the compatible,
visually correct GPU-rendering base on which tile scheduling and reuse work.

### Frustum Culling Is Currently Unusable

Frustum culling has been tested on-device and must remain disabled
(`GpuMapSettings.frustumCulling = false`). Enabling it produces a rectangle
artifact around the centre of the map and causes text to disappear, which
breaks the rendered map.

The cause is not yet determined. The orthographic camera may not expose the
correct culling frustum after the Flutter GPU migration, or frustum culling may
be broken in the current renderer/engine combination. Treat it as unsupported
until the camera bounds and engine behaviour are investigated and verified.

## Pre-existing SDF Shader Correction

The current working tree also contains a pre-existing change in both SDF
generation stages:

- `shaders/sdf_gen/vector_tile_renderer$stage_a.frag`
- `shaders/sdf_gen/vector_tile_renderer$stage_b.frag`

The upper scan bound is clamped with `min(..., 1)`, matching the lower bound's
`max(..., 0)`. The previous `max(..., 1)` forced the scan to the atlas edge,
even when the configured SDF radius had already been reached. Keep this
change: it reduces unnecessary fragment work without changing the configured
distance range or dropping glyph data.

## Current Uncommitted Smoothing Work

### Render only required glyphs

`AtlasCreatingTextVisitor` no longer creates a default atlas containing all
256 low character codes whenever a tile uses ordinary text. It now builds
atlases only from the characters present in the tile, still chunking at 256
characters when required.

This removes the frequent 16x16-cell initial atlas. In profile logs, typical
atlases are now based on the actual tile content, for example 54 or 65 glyphs.
All required labels are still generated; the work is smaller, not omitted.

### Serialize atlas generation globally

`AtlasGenerator` queues SDF atlas generation through one static future tail.
The tail is static so the world and text renderer instances cannot launch
competing atlas jobs at the same time. It also waits for an end-of-frame before
starting the next job, leaving a frame available for gestures.

This intentionally trades peak throughput for frame consistency: new labels
may appear progressively during a fast pan or zoom, but each requested atlas
remains queued and is eventually generated. It does not discard tiles,
geometry, or text.

### Retain recently off-screen GPU tile nodes

`TilesRenderer` retains a least-recently-used cache of fully prepared GPU
`Node`s. Returning to the same `z/x/y` tile can reuse its geometry, materials,
buffers, textures, and atlas ownership instead of unpacking it again.

`GpuMapSettings.tileNodeCacheCapacity` controls the cache:

- `0` disables it.
- `12` is the renderer fallback when an application does not override it.
- The current application default is `32`, set in
  `common/apollo_uikit/lib/src/map/widgets/partials/`
  `flutter_map_vector_tile_layer.dart`. Change that value for an on-device
  GPU-memory/cache-size comparison.

Larger values improve same-zoom backtracking pans but retain more GPU memory.
They do not provide exact matches for a different zoom level, because the
tile coordinates and tile contents change.

Cached node keys are included when unused glyph atlases and textures are
released. A cached node therefore keeps the atlas textures it needs; it cannot
be restored with missing text textures.

### Profiling Output

The temporary `[PERF]` console prints used for device profiling have been
removed. Historical logs use `atlas`, `preRenderUi`, and `update` entries to
show glyph raster/readback time, SDF command recording/submission time, atlas
wait/work time, and tile-node reuse.

The historical `sdf_gpu` field is not a GPU fence measurement. It captures
CPU-side time to issue SDF work; readback and queue waits can include prior GPU
work. Similarly, a large historical `preRenderUi` total can be deliberate
queue latency rather than one uninterrupted UI/GPU operation.

## What This Does Not Cache

The upstream `vector_map_tiles` cache stores raw vector tile (`.pbf`) bytes.
It still decodes and prepares render data before this renderer receives a tile.
The GPU node cache begins later in the pipeline and avoids rebuilding already
prepared GPU scene content when a tile returns.

The renderer does not persist rendered tiles as disk raster images. Raster
serialization and later image upload would add I/O, memory pressure, texture
upload work, and invalidation concerns for theme, device scale, and style
changes. The in-memory GPU node cache is the appropriate first-level reuse
mechanism for interactive panning.

## Combined Behaviour and Benefit

The branch now operates as one GPU tile-rendering pipeline:

1. The migrated Flutter GPU scene and shaders render map layers in the correct
   order, with correct transparency and text scale.
2. For a new tile, the renderer identifies the characters used by that tile
   and creates only the needed SDF glyph atlas.
3. Atlas jobs run one at a time across renderer instances, with a frame between
   jobs, rather than all incoming tiles competing for the GPU together.
4. The completed tile geometry, materials, textures, and glyph atlas are
   retained in a small GPU-node LRU cache after the tile leaves the viewport.
5. Returning to the same tile reattaches its prepared GPU node. It does not
   rebuild geometry or regenerate its still-owned glyph atlas.

The combined result is a correct Flutter GPU map that avoids the previous
all-at-once atlas workload. Pans and zooms remain responsive because expensive
text preparation is spread over time, while prior tiles remain visible until
their replacements are ready. Revisiting nearby tiles at the same zoom is
faster because their GPU representation can be reused.

Nothing is skipped: every requested tile, feature, and label is eventually
rendered. The deliberate tradeoff is progressive arrival of new labels during
fast movement. A first-time tile can still have an expensive glyph
raster/readback operation, and a different zoom level cannot reuse a tile node
with different coordinates/content.

## Current Result and Next Direction

The expected profile shape is smaller interaction freezes, frequent
`newTiles=0` / `cachedTiles>0` reuse when revisiting an area, and later
progressive arrival of new labels during aggressive movement. This resolves
the dominant simultaneous atlas-generation burst while preserving complete map
output. A single large glyph readback can still be costly, so the work reduces
peak contention rather than guaranteeing that every tile completes instantly.

The remaining improvement is motion-aware scheduling: while the camera is
actively moving, keep the old tile pyramid visible and defer expensive text
atlas preparation until motion settles. That requires a deliberate integration
with `vector_map_tiles` camera/map-event state; it should not be approximated
with an uncoordinated timer in this renderer.
