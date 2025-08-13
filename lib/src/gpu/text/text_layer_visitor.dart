
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/sdf_atlas_manager.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_builder.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';

class TextLayerVisitor {
  final SceneGraph graph;
  final VisitorContext context;
  final GeometryWorkers geometryWorkers;

  TextLayerVisitor(this.graph, this.context, this.geometryWorkers);

  Future<void> addFeatures(Style style, Iterable<LayerFeature> features) async {

    final List<Future<dynamic>> futures = [];
    for (var feature in features) {

      final symbolLayout = style.symbolLayout;
      if (symbolLayout == null) {
        print("null layout, skipping");
        return;
      }

      final evaluationContext = EvaluationContext(
              () => feature.feature.properties, TileFeatureType.none, context.logger,
          zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

      final text = symbolLayout.text?.text.evaluate(evaluationContext);


      final point = feature.feature.modelPoints.firstOrNull ?? feature.feature.modelLines.map((it) {
        return it.points[it.points.length ~/ 2];
      }).firstOrNull;

      if (point == null) {
        continue;
      }

      if (text == null || text.isEmpty) {
        continue;
      }

      if (point.x < 0 || point.x > 4096 || point.y < 0 || point.y > 4096) {
        continue;
      }

      futures.add(TextBuilder(_atlasManager).addText(text, 64, point.x, point.y, 4096, graph));
    }
    await Future.wait(futures);
  }

  static final _atlasManager = SdfAtlasManager();

}