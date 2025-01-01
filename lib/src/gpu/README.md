 - Get device max texture resolution instead of constant limit

Lines:
 - Ensure that line points don't overflow the array buffer
 - Fix line width to scale with actual extent/tile size instead of hard coded value
 - Add support for remaining line join and line end styles
 
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