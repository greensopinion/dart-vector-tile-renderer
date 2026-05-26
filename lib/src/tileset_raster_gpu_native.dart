// Native platform shim: re-exports GPU types needed by tileset_raster.dart.
// Used via conditional import — only compiled on platforms where dart:ffi
// is available (Android, iOS, desktop). Never imported on web.
export 'package:flutter_gpu/gpu.dart' show Texture;
export 'package:flutter_scene/scene.dart' show gpuTextureFromImage;
