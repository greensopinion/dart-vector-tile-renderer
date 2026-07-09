import 'package:flutter_gpu/gpu.dart' as gpu;

const String _kShaderBundlePath =
    'packages/vector_tile_renderer/build/shaderbundles/tile.shaderbundle';

gpu.ShaderLibrary? _shaderLibrary;

/// The tile shader bundle.
///
/// Reading a shader bundle from an asset is asynchronous on every backend,
/// so the bundle must be loaded ahead of time by awaiting [loadShaderLibrary]
/// (driven by `TilesRenderer.initialize`); accessing this getter before that
/// completes throws.
gpu.ShaderLibrary get shaderLibrary {
  final cached = _shaderLibrary;
  if (cached == null) {
    throw Exception(
      'The tile shader bundle has not been loaded yet. Await '
      'loadShaderLibrary() (via TilesRenderer.initialize) before '
      'constructing geometry or materials that touch the shader library.',
    );
  }
  return cached;
}

/// Asynchronously loads and caches the tile shader bundle. Idempotent.
///
/// Called by `TilesRenderer` during initialization so the synchronous
/// [shaderLibrary] getter has a cached library to return (shader assets
/// can't be read synchronously on any backend).
Future<void> loadShaderLibrary() async {
  if (_shaderLibrary != null) {
    return;
  }
  final lib = await gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);
  if (lib == null) {
    throw Exception("Failed to load shader bundle! ($_kShaderBundlePath)");
  }
  _shaderLibrary = lib;
}
