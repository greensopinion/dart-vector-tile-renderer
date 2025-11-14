
# Development

## Flutter Version

This project requires flutter_gpu, which is currently only available on the main channel. To setup, run:

```sh
flutter channel main && flutter upgrade
```

## Project Setup

In IOS and MacOS, set `FLTEnableFlutterGPU` to true in the Info.plist

```xml
    <key>FLTEnableImpeller</key>
    <true/>
    <key>FLTEnableFlutterGPU</key>
    <true/>
```

On Android, set `io.flutter.embedding.android.EnableFlutterGPU` to true in metadata (where?)

## Building Shaders

To build shaders:

```sh
flutter clean && flutter pub get
cd example && flutter run
```

# Features

## Todo
- Stretchable icons? Some icons are missing, this might be why
- Icons at zoom sub-levels? Might not be helpful or necessary
- outlines
- support duplicate layer id
- DEM tiles
  - hillshade
  - contour lines
    - elevation labels
- 3d tiltable maps
  - fill extrusion
  - elevation
- Different font weights
   - Not implementing yet, because the currently used SDF approximation forces us to draw all text with a heavy font weight.
- correct halo radius for text
   - Not implementing yet, because increasing the halo radius much beyond its current fixed value results in characters overlapping with each other within a single label. Fixing this would require doubling the number of draw calls for text, which would result in a significant performance hit. Maybe there's a better solution, but I can't think of one right now.


## Background
 - done
   - color

## Fill
 - done
   - color
   - outlines

## Line
 - done
   - caps + joins
   - thickness
   - variable thickness
   - dashed lines

## Raster
 - done
 
## Symbol
 - done
   - text size
   - point/line alignment
   - rotation alignment
   - variable size
   - concurrent pre-render optimizations
   - different fonts
   - batching optimizations
   - overlap prevention (text collision)
   - text optimizations (eg. street -> st.)
   - dynamic char code range
   - multi-line text (line breaks)
   - better overlap prevention
   - Sdf "softness" adjusted for text size (fix fuzzy text with large text size)
   - Italic text
   - Shift text along line to fit better in label space
   - Respect anchor from theme
   - Line text follows line closely instead of rotating entire text feature to average angle of line
   - non-text symbols

## Fill Extrusion
 - done
   - draws