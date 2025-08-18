import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/background/background_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_material.dart';
import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry.dart';

import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

import 'line/line_geometry.dart';

class BucketUnpacker {
  void unpackOnto(SceneGraph graph, TileRenderData bucket) {
    for (var packedMesh in bucket.data) {
      graph.addMesh(Mesh(_unpackGeometry(packedMesh.geometry), _unpackMaterial(packedMesh.material)));
    }
  }

  Material _unpackMaterial(PackedMaterial packed) => _materialConstructors[packed.type.index].call(packed);

  Geometry _unpackGeometry(PackedGeometry packed) => _geometryConstructors[packed.type.index].call(packed);
}

enum GeometryType {
  line,
  polygon,
  background,
  raster,
  text;
}

enum MaterialType {
  line,
  colored,
  raster,
  text;
}

final _geometryConstructors = [
  (a) => LineGeometry(a),
  (a) => PolygonGeometry(a),
  (a) => BackgroundGeometry(),
  // TODO
];

final _materialConstructors = [
  (a) => LineMaterial(a),
  (a) => ColoredMaterial(a),
  // TODO
];
