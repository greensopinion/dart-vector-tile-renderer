import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_material.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_material.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';

import 'background/background_geometry.dart';
import 'colored_material.dart';
import 'line/line_geometry.dart';
import 'line/line_material.dart';
import 'polygon/polygon_geometry.dart';
import 'tile_render_data.dart';

class BucketUnpacker {

  final TextureProvider textureProvider;

  BucketUnpacker(this.textureProvider);

  void unpackOnto(Node parent, TileRenderData bucket) {
    for (var packedMesh in bucket.data) {
      Node? node;

      switch (packedMesh.material.type) {
        case MaterialType.line:
        case MaterialType.colored:
        case MaterialType.raster:
          parent.addMesh(Mesh(_unpackGeometry(packedMesh.geometry), _unpackMaterial(packedMesh.material)));
          continue;
        case MaterialType.text:
          node = Node(localTransform: Matrix4.identity()..translate(0.0, 0.0, 0.00000001));
        case MaterialType.textHalo:
          node = Node(localTransform: Matrix4.identity()..translate(0.0, 0.0, 0.00000002));
      }
      node.addMesh(Mesh(_unpackGeometry(packedMesh.geometry), _unpackMaterial(packedMesh.material)));
      parent.add(node);
    }
  }

  Material _unpackMaterial(PackedMaterial packed) =>
      _materialConstructors[packed.type.index]!.call(packed, textureProvider);

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
  text,
  textHalo;
}

final _geometryTypeToConstructor = {
  GeometryType.line: (a) => LineGeometry(a),
  GeometryType.polygon: (a) => PolygonGeometry(a),
  GeometryType.background: (a) => BackgroundGeometry(),
  GeometryType.raster: (a) => throw UnimplementedError(),
  GeometryType.text: (a) => TextGeometry(a)
};

final _geometryConstructors =
    GeometryType.values.map((v) => _geometryTypeToConstructor[v]).toList();

final _materialTypeToConstructor = {
  MaterialType.line: (a, b) => LineMaterial(a),
  MaterialType.colored: (a, b) => ColoredMaterial(a),
  MaterialType.raster: (a, b) => throw UnimplementedError(),
  MaterialType.text: (a, b) => TextMaterial(a, b),
  MaterialType.textHalo: (a, b) => TextMaterial(a, b)
};

final _materialConstructors =
    MaterialType.values.map((v) => _materialTypeToConstructor[v]).toList();
