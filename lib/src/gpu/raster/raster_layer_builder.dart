import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'raster_material.dart';
import 'raster_geometry.dart';

import '../../../vector_tile_renderer.dart';

class RasterLayerBuilder {


  void build(Node parent, ByteData packedTileKey, ByteData packedPaintModel, RasterTileset rasterTileset) {

    final bytes = Uint8List.fromList(packedTileKey.buffer.asUint8List(
      packedTileKey.offsetInBytes,
      packedTileKey.lengthInBytes,
    ));

    final uint16View = bytes.buffer.asUint16List();
    final tileKey = String.fromCharCodes(uint16View);

    final rasterTile = rasterTileset.tiles[tileKey];

    final opacity = packedPaintModel.getFloat64(0, Endian.little);

    final resampling = packedPaintModel.getFloat64(8, Endian.little);



    if (rasterTile == null) {
      return;
    } else {
      final texture = rasterTile.texture;
      if (texture != null) {

        RasterMaterial material =
        RasterMaterial(colorTexture: texture, resampling: resampling);
        material.baseColorFactor = Vector4(1.0, 1.0, 1.0, opacity);

        parent.addMesh(Mesh(RasterGeometry(rasterTile), material));
      }
    }
  }
}
