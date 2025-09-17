
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

---
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
 - todo
   - needs fixing, currently doesn't draw at all
 
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

- todo
   - better overlap prevention
   - dynamic char code range
   - non-text symbols
   - correct halo radius
   - text optimizations (eg. street -> st)
   - Line text follows line closely instead of rotating entire text feature to average angle of line
   - Sdf "softness" adjusted for text size (fix fuzzy text with large text size)
   - Respect anchor from theme

## Fill Extrusion
 - done
   - draws
 - todo
   - 3d