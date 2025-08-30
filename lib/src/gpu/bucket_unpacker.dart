import 'package:flutter_scene/scene.dart';

import 'background/background_geometry.dart';
import 'colored_material.dart';
import 'line/line_geometry.dart';
import 'line/line_material.dart';
import 'polygon/polygon_geometry.dart';
import 'tile_render_data.dart';

class BucketUnpacker {
  void unpackOnto(Node parent, TileRenderData bucket) {
    for (var packedMesh in bucket.data) {
      parent.addMesh(Mesh(_unpackGeometry(packedMesh.geometry),
          _unpackMaterial(packedMesh.material)));
    }
  }

  Material _unpackMaterial(PackedMaterial packed) =>
      _materialConstructors[packed.type.index]!.call(packed);

  Geometry _unpackGeometry(PackedGeometry packed) =>
      _geometryConstructors[packed.type.index]!.call(packed);
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

final _geometryTypeToContructor = {
  GeometryType.line: (a) => LineGeometry(a),
  GeometryType.polygon: (a) => PolygonGeometry(a),
  GeometryType.background: (a) => BackgroundGeometry(),
};

final _geometryConstructors =
    GeometryType.values.map((v) => _geometryTypeToContructor[v]).toList();

final _materialTypeToContructor = {
  MaterialType.line: (a) => LineMaterial(a),
  MaterialType.colored: (a) => ColoredMaterial(a)
};

final _materialConstructors =
    MaterialType.values.map((v) => _materialTypeToContructor[v]).toList();
