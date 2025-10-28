
import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/tile_source.dart';

import '../tile_render_data.dart';
import 'icon_geometry.dart';
import 'icon_material.dart';

class IconLayerBuilder {
  final TileSource tileSource;
  final Texture? spritesTexture;

  final List<double> vertices = [];

  IconLayerBuilder(this.tileSource, this.spritesTexture);

  Mesh? build() {
    final texture = spritesTexture;
    if (texture == null || vertices.isEmpty) {
      return null;
    }
    final geom = IconGeometry(Float32List.fromList(vertices));
    final mat = IconMaterial(colorTexture: texture, resampling: 1.0);

    return Mesh(geom, mat);
  }

  void add(PackedMesh packedMesh) {
    final uniform = packedMesh.geometry.uniform!;
    final vtx = packedMesh.geometry.vertices;

    final bytes = Uint8List.fromList(uniform.buffer.asUint8List(
      uniform.offsetInBytes,
      uniform.lengthInBytes,
    ));

    final uint16View = bytes.buffer.asUint16List();
    final spriteName = String.fromCharCodes(uint16View);

    final sprite = tileSource.spriteIndex?.spriteByName[spriteName];
    final texture = spritesTexture;

    if (tileSource.spriteAtlas != null && texture != null && sprite != null) {

      const tileSize = 256;

      final u0 = sprite.x / texture.width;
      final v0 = (sprite.y + sprite.height) / texture.height;
      final u1 = (sprite.x + sprite.width) / texture.width;
      final v1 = sprite.y / texture.height;

      double scale = (sprite.pixelRatio == 1 ? 1 : 1 / sprite.pixelRatio) / tileSize;

      final width = sprite.width * scale;
      final height = sprite.height * scale;

      final pointBytes = Uint8List.fromList(vtx.buffer.asUint8List(
        vtx.offsetInBytes,
        vtx.lengthInBytes,
      ));

      final point = pointBytes.buffer.asFloat32List();

      final xA = point[0];
      final yA = point[1];

      final x0 = -width;
      final y0 = -height;

      final x1 = width;
      final y1 = height;

       vertices.addAll([
        xA, yA, x0, y0, u0, v0,
        xA, yA, x1, y0, u1, v0,
        xA, yA, x1, y1, u1, v1,
        xA, yA, x0, y1, u0, v1
      ]);
    }
  }
}