import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'test_files.dart';
import 'test_logger.dart';

Future<Tile> readTestTile(Theme theme) async {
  final bytes = await readTestFile('sample_tile.pbf');
  return TileFactory(theme, testLogger).create(VectorTileReader().read(bytes));
}
