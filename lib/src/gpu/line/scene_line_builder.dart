import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_geometry_builder.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../bucket_unpacker.dart';

class FeatureGroup {
  final List<List<TilePoint>> lines = [];
  int size = 0;
}

class SceneLineBuilder {
  final TileRenderData renderData;
  final VisitorContext context;

  SceneLineBuilder(this.renderData, this.context);

  void addFeatures(Style style, Iterable<LayerFeature> features) {
    Map<PaintModel, List<FeatureGroup>> featureGroups = {};
    for (final feature in features) {
      final result = _getLines(style, feature);
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
        _addMesh(
          lines.lines,
          paint.strokeWidth!,
          features.first.layer.extent,
          paint,
          paint.strokeDashPattern,
        );
      }
    });
  }

  (PaintModel, Iterable<List<TilePoint>>)? _getLines(
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
                  poly.rings.map(
                      (ring) => List.of(ring.points)..add(ring.points.first))
                })
            .flattened
            .toList();

        return (paint, outlines);
      }
    }
    return null;
  }

  void _addMesh(List<List<TilePoint>> lines, double lineWidth,
      int extent, PaintModel paint, List<double>? dashLengths) {
    final (vertices, indices) = LineGeometryBuilder().build(
      lines,
      paint.lineCap ?? LineCap.DEFAULT,
      paint.lineJoin ?? LineJoin.DEFAULT,
    );

    final ByteData geomUniform = Float32List.fromList([
      lineWidth / 128,
      extent / 2,
    ]).buffer.asByteData();

    final color = paint.color.vector4;

    final ByteData materialUniform = Float32List.fromList([
      color.x,
      color.y,
      color.z,
      color.w,
      dashLengths?[0] ?? 64.0,
      dashLengths?[1] ?? 0.0,
    ]).buffer.asByteData();

    renderData.addMesh(
      PackedMesh(
          PackedGeometry(vertices: vertices, indices: indices, uniform: geomUniform, type: GeometryType.line),
          PackedMaterial(uniform: materialUniform, type: MaterialType.line))
    );
  }
}
