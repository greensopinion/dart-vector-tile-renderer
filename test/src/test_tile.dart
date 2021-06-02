import 'dart:io';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

Future<VectorTile> readTestTile() async {
  final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
  return VectorTileReader().read(bytes);
}
