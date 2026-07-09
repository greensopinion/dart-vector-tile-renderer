/// Anti-aliasing quality for the flutter_gpu vector map.
///
/// Higher quality means smoother edges but more GPU cost per frame. On slow
/// devices, dropping from [msaa] to [fxaa] or [none] is the biggest single
/// performance lever.
enum MapAntiAliasing {
  /// No anti-aliasing. Fastest; edges are aliased ("pixelated").
  none,

  /// Cheap full-screen post-process AA. Softer edges at low cost.
  fxaa,

  /// 4x multisample AA. Best edge quality, highest cost (the historical
  /// default). Falls back to [fxaa] on backends without MSAA support.
  msaa,

  /// MSAA where the backend supports it, otherwise FXAA.
  auto,
}

/// Global, mutable performance/quality knobs for the flutter_gpu vector map
/// renderer (`TilesRenderer`).
///
/// These are process-wide (the renderer is created deep inside
/// `vector_map_tiles`, which exposes no configuration hook), so set them once —
/// e.g. from app startup or a debug settings screen — to trade quality for
/// frame rate. [antiAliasing] applies on the next rendered frame;
/// [frustumCulling] applies the next time tiles are (re)built (pan/zoom or a
/// hot restart).
class GpuMapSettings {
  GpuMapSettings._();

  /// Anti-aliasing mode. Defaults to [MapAntiAliasing.msaa].
  static MapAntiAliasing antiAliasing = MapAntiAliasing.msaa;

  /// Whether to frustum-cull tile geometry outside the camera view.
  ///
  /// When `true`, off-screen geometry is skipped, cutting draw calls when many
  /// tiles are loaded. When `false` (default) every tile in the scene is drawn
  /// each frame.
  ///
  /// Experimental: the map's orthographic camera does not yet produce a tight
  /// view frustum, so enabling this can drop visible tiles — verify on-device.
  static bool frustumCulling = false;
}
