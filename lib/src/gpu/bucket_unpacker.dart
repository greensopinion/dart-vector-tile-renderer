import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/icon/icon_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_layer_builder.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_material.dart';
import 'package:vector_tile_renderer/src/gpu/text/render/curved_text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/render/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/render/text_material.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';
import 'package:vector_tile_renderer/src/tileset_raster.dart';

import '../../vector_tile_renderer.dart';
import 'background/background_geometry.dart';
import 'colored_material.dart';
import 'icon/icon_layer_builder.dart';
import 'icon/icon_material.dart';
import 'line/line_geometry.dart';
import 'line/line_material.dart';
import 'polygon/polygon_geometry.dart';
import 'tile_render_data.dart';

class BucketUnpacker {
  final TextureProvider textureProvider;
  final TileSource tileSource;

  final Texture? spritesTexture;

  BucketUnpacker(this.textureProvider, this.tileSource, this.spritesTexture);

  void unpackOnto(Node parent, TileRenderData bucket) {
    final iconBuilder = IconLayerBuilder(tileSource, spritesTexture);

    for (var packedMesh in bucket.data) {
      if (packedMesh.geometry.type == GeometryType.raster) {
        RasterLayerBuilder().build(parent, packedMesh.geometry.uniform!,
            packedMesh.material.uniform!, tileSource.rasterTileset);
      } else if (packedMesh.geometry.type == GeometryType.icon) {
        iconBuilder.add(packedMesh);
      } else {
        parent.addMesh(Mesh(_unpackGeometry(packedMesh.geometry),
            _unpackMaterial(packedMesh.material)));
      }
    }
    final icons = iconBuilder.build();
    if (icons != null) {
      parent.addMesh(icons);
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
  curvedText,
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
  GeometryType.text: (a) => TextGeometry(a),
  GeometryType.curvedText: (a) => CurvedTextGeometry(a)
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
