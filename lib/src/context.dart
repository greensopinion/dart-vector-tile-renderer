import 'dart:ui';

import 'features/feature_renderer.dart';
import 'features/label_space.dart';
import 'features/tile_space_mapper.dart';
import 'logger.dart';
import 'model/tile_model.dart';
import 'optimizations.dart';
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
  late TileSpaceMapper tileSpaceMapper;

  Context(
      this.logger,
      this.canvas,
      this.featureRenderer,
      this.tileset,
      this.zoomScaleFactor,
      this.zoom,
      this.tileSpace,
      this.tileClip,
      this.optimizations)
      : labelSpace = LabelSpace(tileClip);

  Tile? tile(String sourceId) => tileset.tiles[sourceId];
}
