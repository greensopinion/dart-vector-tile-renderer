import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'features/feature_renderer.dart';
import 'features/label_space.dart';
import 'logger.dart';

class Context {
  final Logger logger;
  final Canvas canvas;
  final FeatureDispatcher featureRenderer;
  final Map<String, VectorTile> _tiles;
  final double zoomScaleFactor;
  final double zoom;
  final Rect tileSpace;
  final Rect tileClip;
  late final LabelSpace labelSpace;

  Context(
      this.logger,
      this.canvas,
      this.featureRenderer,
      Map<String, VectorTile> tiles,
      this.zoomScaleFactor,
      this.zoom,
      this.tileSpace,
      this.tileClip)
      : labelSpace = LabelSpace(tileSpace),
        _tiles = tiles;

  VectorTile? tile(String sourceId) => _tiles[sourceId];
}
