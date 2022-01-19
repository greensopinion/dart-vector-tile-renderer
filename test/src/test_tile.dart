import 'dart:io';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'test_logger.dart';

Future<Tile> readTestTile(Theme theme) async {
  final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
  return TileFactory(theme, testLogger).create(VectorTileReader().read(bytes));
}
