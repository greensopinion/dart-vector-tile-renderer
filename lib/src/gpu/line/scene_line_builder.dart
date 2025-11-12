import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import '../color_extension.dart';
import 'line_geometry_builder.dart';
import '../tile_render_data.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../geometry_unpacker.dart';

class FeatureGroup {
  final List<List<TilePoint>> lines = [];
  int size = 0;
}

class PaintGroup {
  final PaintModel paint0;
  late final PaintModel paint1;

  PaintGroup(this.paint0, PaintModel? paint1) {
    this.paint1 = paint1 ?? paint0;
  }

  @override
  bool operator ==(Object other) {
    return other is PaintGroup && paint0 == other.paint0;
  }

  @override
  int get hashCode => paint0.hashCode;
}

class SceneLineBuilder {
  final TileRenderData renderData;
  final VisitorContext context;

  SceneLineBuilder(this.renderData, this.context);

  void addFeatures(Style style, Iterable<LayerFeature> features) {
    Map<PaintGroup, FeatureGroup> featureGroups = {};
    for (final feature in features) {
      final result = _getLines(style, feature);
      if (result != null) {
        final (paint, lines) = result;

        if (!featureGroups.containsKey(paint)) {
          featureGroups[paint] = FeatureGroup();
        }

        var group = featureGroups[paint]!;

        group.size += lines.fold(0, (sum, line) => sum + line.length);

        group.lines.addAll(lines);
      }
    }

    featureGroups.forEach((paint, group) {
      _addMesh(
        group.lines,
        paint,
      );
    });
  }

  (PaintGroup, Iterable<List<TilePoint>>)? _getLines(
      Style style, LayerFeature feature) {
    EvaluationContext evaluationContext0 = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom.floorToDouble(),
        zoomScaleFactor: 1.0,
        hasImage: (_) => false);

    EvaluationContext evaluationContext1 = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom.ceilToDouble(),
        zoomScaleFactor: 1.0,
        hasImage: (_) => false);

    final paint0 = style.linePaint?.evaluate(evaluationContext0);
    final paint1 = style.linePaint?.evaluate(evaluationContext1);

    if (paint0 != null &&
        paint0.strokeWidth != null &&
        paint0.strokeWidth! > 0) {
      if (feature.feature.modelLines.isNotEmpty) {
        return (
          PaintGroup(paint0, paint1),
          feature.feature.modelLines.map((it) => it.points)
        );
      } else if (feature.feature.modelPolygons.isNotEmpty) {
        var outlines = feature.feature.modelPolygons
            .expand((poly) => {
                  poly.rings.map(
                      (ring) => List.of(ring.points)..add(ring.points.first))
                })
            .flattened
            .toList();

        return (PaintGroup(paint0, paint1), outlines);
      }
    }
    return null;
  }

  void _addMesh(List<List<TilePoint>> lines, PaintGroup paints) {
    final (vertices, indices) = LineGeometryBuilder().build(
      lines,
      paints.paint0.lineCap ?? LineCap.DEFAULT,
      paints.paint0.lineJoin ?? LineJoin.DEFAULT,
    );

    final stroke0 = paints.paint0.strokeWidth!;
    final stroke1 = paints.paint1.strokeWidth ?? stroke0;

    final ByteData geomUniform = Float32List.fromList([
      pow(2, context.zoomOffset) * stroke0 / 128,
      1 - (log(stroke1 / stroke0) / ln2),
    ]).buffer.asByteData();

    final color = paints.paint0.color.vector4;

    final dashLengths = paints.paint0.strokeDashPattern;

    final ByteData materialUniform = Float32List.fromList([
      color.x,
      color.y,
      color.z,
      color.w,
      dashLengths?[0] ?? 64.0,
      dashLengths?[1] ?? 0.0,
    ]).buffer.asByteData();

    renderData.addMesh(PackedMesh(
        PackedGeometry(
            vertices: vertices,
            indices: indices,
            uniform: geomUniform,
            type: GeometryType.line),
        PackedMaterial(uniform: materialUniform, type: MaterialType.line)));
  }
}
