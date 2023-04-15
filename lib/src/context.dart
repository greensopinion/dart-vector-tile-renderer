import 'dart:ui';

import 'features/feature_renderer.dart';
import 'features/label_space.dart';
import 'features/tile_space_mapper.dart';
import 'logger.dart';
import 'model/tile_model.dart';
import 'optimizations.dart';
import 'symbols/text_painter.dart';
import 'themes/paint_factory.dart';
import 'tile_source.dart';

class Context {
  final Logger logger;
  final Canvas canvas;
  final FeatureDispatcher featureRenderer;
  final TileSource tileSource;
  final double zoomScaleFactor;
  final double zoom;
  final Rect tileSpace;
  final Rect tileClip;
  final LabelSpace labelSpace;
  final Optimizations optimizations;
  final TextPainterProvider textPainterProvider;
  final CachingPaintProvider paintProvider;
  late TileSpaceMapper tileSpaceMapper;

  Context(
      {required this.logger,
      required this.canvas,
      required this.featureRenderer,
      required this.tileSource,
      required this.zoomScaleFactor,
      required this.zoom,
      required this.tileSpace,
      required this.tileClip,
      required this.optimizations,
      required this.textPainterProvider})
      : labelSpace = LabelSpace(tileClip),
        paintProvider = CachingPaintProvider();

  Tile? tile(String sourceId) => tileSource.tileset.tiles[sourceId];
}
