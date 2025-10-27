import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/icon/icon_geometry.dart';
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

  final Texture? spritesTexture;

  BucketUnpacker(this.textureProvider, this.tileSource, this.spritesTexture);

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

        if (tileSource.spriteAtlas != null && spritesTexture != null && sprite != null) {
          final texture = spritesTexture!;

          const tileSize = 256;

          final u0 = sprite.x / texture.width;
          final v0 = (sprite.y + sprite.height) / texture.height;
          final u1 = (sprite.x + sprite.width) / texture.width;
          final v1 = sprite.y / texture.height;

          double scale = (sprite.pixelRatio == 1 ? 1 : 1 / sprite.pixelRatio) / tileSize;

          final width = sprite.width * scale;
          final height = sprite.height * scale;

          final x0 = 0.0;
          final y0 = 0.0;

          final x1 = x0 + width;
          final y1 = y0 + height;

          final vertices = Float32List.fromList([
            x0, y0, 0.0, u0, v0,
            x1, y0, 0.0, u1, v0,
            x1, y1, 0.0, u1, v1,
            x0, y1, 0.0, u0, v1
          ]);

          final geom = IconGeometry(vertices);
          final mat = RasterMaterial(colorTexture: texture, resampling: 1.0);

          parent.addMesh(Mesh(geom, mat));

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
