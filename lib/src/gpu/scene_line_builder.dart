import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
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
    UnskinnedGeometry geometry = UnskinnedGeometry();
    geometry.setVertexShader(shaderLibrary["LineVertex"]!);
    final pointCount = feature.feature.modelLines.expand((it) => {it.points}).length;

    List<Vector3> vertices = List.empty(growable: true);

    if (pointCount < 2) return;

    final segmentCount = pointCount - 1;

    for (int i = 0; i < segmentCount; i++) {
      double p0 = i + 0;
      double p1 = i + 1;
      vertices.add(Vector3(p0, 1, p1));
      vertices.add(Vector3(p0, 0, p1));
      vertices.add(Vector3(p1, 1, p0));

      vertices.add(Vector3(p1, 1, p0));
      vertices.add(Vector3(p1, 0, p0));
      vertices.add(Vector3(p0, 0, p1));
    }

    scene.addMesh(Mesh(geometry, UnlitMaterial()));
  }
}
