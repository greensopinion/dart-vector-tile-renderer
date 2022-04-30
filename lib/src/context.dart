import 'dart:ui';

import 'features/feature_renderer.dart';
import 'features/label_space.dart';
import 'features/tile_space_mapper.dart';
import 'logger.dart';
import 'model/tile_model.dart';
import 'optimizations.dart';
import 'symbols/text_painter.dart';
import 'tileset.dart';

class Context {
  final Logger logger;
  final Canvas canvas;
  final FeatureDispatcher featureRenderer;
  final Tileset tileset;
  final double zoomScaleFactor;
  final double zoom;
  final Rect tileSpace;
  final Rect tileClip;
  final LabelSpace labelSpace;
  final Optimizations optimizations;
  final TextPainterProvider textPainterProvider;
  late TileSpaceMapper tileSpaceMapper;

  Context(
      {required this.logger,
      required this.canvas,
      required this.featureRenderer,
      required this.tileset,
      required this.zoomScaleFactor,
      required this.zoom,
      required this.tileSpace,
      required this.tileClip,
      required this.optimizations,
      required this.textPainterProvider})
      : labelSpace = LabelSpace(tileClip);

  Tile? tile(String sourceId) => tileset.tiles[sourceId];
}
