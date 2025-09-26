
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

- todo
   - non-text symbols
   - correct halo radius
   - Line text follows line closely instead of rotating entire text feature to average angle of line
   - Respect anchor from theme
   - Different font weights
   - Shift text along line to fit better in label space

## Fill Extrusion
 - done
   - draws
 - todo
   - 3d