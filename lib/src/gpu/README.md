
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

## Visual Quality

 - Rendering on a second monitor on a Mac laptop causes pixelation

## Overzooming

 - Tile clip causes artifacts at tile boundaries (consider clipping with a margin outside of the clip area)

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

- todo
   - better overlap prevention
   - non-text symbols
   - correct halo radius
   - multi-line text (line breaks)
   - Line text follows line closely instead of rotating entire text feature to average angle of line
   - Sdf "softness" adjusted for text size (fix fuzzy text with large text size)
   - Respect anchor from theme

## Fill Extrusion
 - done
   - draws
 - todo
   - 3d