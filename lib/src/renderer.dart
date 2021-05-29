import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'context.dart';
import 'features/feature_renderer.dart';
import 'themes/theme.dart';
import 'logger.dart';

class Renderer {
  final Theme theme;
  final Logger logger;
  final FeatureDispatcher featureRenderer;

  Renderer({required this.theme, Logger? logger})
      : this.logger = logger ?? Logger.noop(),
        featureRenderer = FeatureDispatcher(logger ?? Logger.noop());

  void render(Canvas canvas, VectorTile tile) {
    final context = Context(logger, canvas, featureRenderer, tile);
    theme.layers.forEach((themeLayer) {
      logger.log(() => 'rendering theme layer ${themeLayer.id}');
      themeLayer.render(context);
    });
  }
}
