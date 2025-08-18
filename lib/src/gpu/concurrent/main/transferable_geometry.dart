

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry.dart';

import '../shared/keys.dart';

class TransferableGeometry {
  final Map<String, dynamic> _data;

  TransferableGeometry(this._data);

  static TransferableGeometry build(List<int> indices, List<double> vertices, GeometryType type) {
    return TransferableGeometry({
      GeometryKeys.indices: indices,
      GeometryKeys.vertices: vertices,
      GeometryKeys.type: type.index
    });
  }

  static final _constructors = [
        (a, b) => LineGeometry(a),
        (a, b) => PolygonGeometry(a)
  ];

  Geometry unpack() {
    final typeIndex = _data[GeometryKeys.type];
    final vertices = _data[GeometryKeys.vertices];
    final indices = _data[GeometryKeys.indices];

    return _constructors[typeIndex](vertices, indices);
  }
}