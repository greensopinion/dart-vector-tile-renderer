import '../gpu/tile_renderer_composite.dart';
import '../symbols/text_painter.dart';
import '../themes/theme.dart';
import '../tile_source.dart';

/// Factory interface for creating tile renderers
abstract class TileRendererFactory {
  /// Creates a tile renderer with the specified configuration
  TileRendererComposite createRenderer({
    required Theme theme,
    required TileSource tileSource,
    required bool gpuRenderingEnabled,
    required double zoom,
    required TextPainterProvider painterProvider,
  });
}

/// Default implementation of TileRendererFactory
class DefaultTileRendererFactory implements TileRendererFactory {
  const DefaultTileRendererFactory();
  @override
  TileRendererComposite createRenderer({
    required Theme theme,
    required TileSource tileSource,
    required bool gpuRenderingEnabled,
    required double zoom,
    required TextPainterProvider painterProvider,
  }) {
    return TileRendererComposite(
      theme: theme,
      tile: tileSource,
      gpuRenderingEnabled: gpuRenderingEnabled,
      zoom: zoom,
      painterProvider: painterProvider,
    );
  }
}
