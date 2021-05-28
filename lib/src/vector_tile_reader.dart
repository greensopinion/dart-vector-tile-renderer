import 'dart:typed_data';

import 'package:vector_tile/vector_tile.dart';

class VectorTileReader {
  VectorTile read(Uint8List bytes) {
    return VectorTile.fromBytes(bytes: bytes);
  }
}
