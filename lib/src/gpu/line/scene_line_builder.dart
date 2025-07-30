import 'package:collection/collection.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_material.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import '../concurrent/shared/keys.dart' as keys;

class FeatureGroup {
  final List<List<TilePoint>> lines = [];
  int size = 0;
}

class SceneLineBuilder {
  final SceneGraph graph;
  final VisitorContext context;
  final GeometryWorkers geometryWorkers;

  SceneLineBuilder(this.graph, this.context, this.geometryWorkers);

  void addFeatures(Style style, Iterable<LayerFeature> features) {
    Map<PaintModel, List<FeatureGroup>> featureGroups = {};
    for (final feature in features) {
      final result = getLines(style, feature);
      if (result != null) {
        final (paint, lines) = result;

        if (!featureGroups.containsKey(paint)) {
          featureGroups[paint] = [FeatureGroup()];
        }

        if (featureGroups[paint]!.last.size > 4096) {
          featureGroups[paint]!.add(FeatureGroup());
        }
        
        var group = featureGroups[paint]!.last;
        
        group.size += lines.fold(0, (sum, line) => sum + line.length);
            
        group.lines.addAll(lines);
      }
    }
    featureGroups.forEach((paint, lineGroups) {
      for (var lines in lineGroups) {
        addMesh(lines.lines, paint.strokeWidth!, features.first.layer.extent, paint,
            paint.strokeDashPattern);
      }
    });
  }

  (PaintModel, Iterable<List<TilePoint>>)? getLines(
      Style style, LayerFeature feature) {
    EvaluationContext evaluationContext = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final paint = style.linePaint?.evaluate(evaluationContext);

    if (paint != null && paint.strokeWidth != null && paint.strokeWidth! > 0) {
      if (feature.feature.modelLines.isNotEmpty) {
        return (paint, feature.feature.modelLines.map((it) => it.points));
      } else if (feature.feature.modelPolygons.isNotEmpty) {
        var outlines = feature.feature.modelPolygons
            .expand((poly) => {
                  poly.rings.map((ring) =>
                      List.of(ring.points)..add(ring.points.first))
                })
            .flattened
            .toList();

        return (paint, outlines);
      }
    }
    return null;
  }

  Future<void> addMesh(List<List<TilePoint>> lines, double lineWidth, int extent,
      PaintModel paint, List<double>? dashLengths) async {

    final geometry = await geometryWorkers.submitLines(
        lines,
        keys.LineJoin.values.firstWhere((it) => it.name == (paint.lineJoin ?? LineJoin.DEFAULT).name),
        keys.LineEnd.values.firstWhere((it) => it.name == (paint.lineCap ?? LineCap.DEFAULT).name)
    );

    geometry.dashLengths = dashLengths;
    geometry.extent = extent;
    geometry.lineWidth = lineWidth;

    graph.addMesh(Mesh(
        geometry,
        LineMaterial(paint.color.vector4, dashLengths,
            antialiasingEnabled: true)));
  }
}
