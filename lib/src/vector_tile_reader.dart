import 'dart:typed_data';

import 'package:vector_tile/vector_tile.dart';

import 'profiling.dart';

class VectorTileReader {
  VectorTile read(Uint8List bytes) {
    return profileSync('ReadTile', () {
      return VectorTile.fromBytes(bytes: bytes);
    });
  }
}
