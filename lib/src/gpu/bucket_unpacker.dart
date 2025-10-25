import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_layer_builder.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_material.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_material.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';
import 'package:vector_tile_renderer/src/tileset_raster.dart';

import '../../vector_tile_renderer.dart';
import 'background/background_geometry.dart';
import 'colored_material.dart';
import 'line/line_geometry.dart';
import 'line/line_material.dart';
import 'polygon/polygon_geometry.dart';
import 'tile_render_data.dart';

class BucketUnpacker {

  final TextureProvider textureProvider;
  final TileSource tileSource;

  BucketUnpacker(this.textureProvider, this.tileSource);

  void unpackOnto(Node parent, TileRenderData bucket) {
    for (var packedMesh in bucket.data) {
      if (packedMesh.geometry.type == GeometryType.raster) {
        RasterLayerBuilder().build(parent, packedMesh.geometry.uniform!, packedMesh.material.uniform!, tileSource.rasterTileset);
      } else if (packedMesh.geometry.type == GeometryType.icon) {
        final uniform = packedMesh.geometry.uniform!;

        final bytes = Uint8List.fromList(uniform.buffer.asUint8List(
          uniform.offsetInBytes,
          uniform.lengthInBytes,
        ));

        final uint16View = bytes.buffer.asUint16List();
        final spriteName = String.fromCharCodes(uint16View);

        final sprite = tileSource.spriteIndex?.spriteByName[spriteName];
        final atlas = tileSource.spriteAtlas;

        if (sprite != null && atlas != null) {
          print(spriteName);
        }
      } else {
        parent.addMesh(Mesh(_unpackGeometry(packedMesh.geometry), _unpackMaterial(packedMesh.material)));
      }
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
  text,
  icon;
}

enum MaterialType {
  line,
  colored,
  raster,
  text,
  icon;
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
};

final _materialConstructors =
    MaterialType.values.map((v) => _materialTypeToConstructor[v]).toList();
