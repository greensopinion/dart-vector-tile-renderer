import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';
import 'package:vector_tile_renderer/src/themes/theme.dart';

class SceneLineBuilder {
  final Scene scene;
  final VisitorContext context;

  SceneLineBuilder(this.scene, this.context);

  void addLines(Style style, Iterable<LayerFeature> features) {
    for (final feature in features) {
      addLine(style, feature);
    }
  }

  void addLine(Style style, LayerFeature feature) {
    final linePoints = feature.feature.modelLines.expand((it) => {it.points}).flattened;

    scene.addMesh(Mesh(LineGeometry(linePoints), UnlitMaterial()));
  }
}
