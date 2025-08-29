
# Development

---
## Project Setup

In IOS and MacOS, set `FLTEnableFlutterGPU` to true in the Info.plist

```
    <key>FLTEnableImpeller</key>
    <true/>
    <key>FLTEnableFlutterGPU</key>
    <true/>
```

On Android, set `io.flutter.embedding.android.EnableFlutterGPU` to true in metadata (where?)

## Building Shaders

To build shaders:

```
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
 - todo
   - variable thickness
   - verify that dashed lines look correct

## Raster
 - todo
   - needs fixing, currently doesn't draw at all
 
## Symbol
 - done
   - text size
   - point/line alignment
   - rotation alignment
 - todo
   - variable size
   - different fonts
   - batching optimizations
   - concurrent pre-render optimizations
   - dynamic char code range
   - non-text symbols
   - correct halo radius
   - overlap prevention (text collision)
   - text optimizations (eg. street -> st)
   - Line text follows line closely instead of rotating entire text feature to average angle of line
   - Sdf "softness" adjusted for text size (fix fuzzy text with large text size)
   - Respect anchor from theme

## Fill Extrusion
 - todo
   - all

## Other To Do's
 - Ordered layers (currently only background, line, and fill layers are ordered correctly)