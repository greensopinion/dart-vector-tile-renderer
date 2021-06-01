import 'dart:io';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'test_files.dart';
import 'test_logger.dart';

void main() {
  Future<void> assertImageWith(VectorTile tile, {required int zoom}) async {
    final renderer = ImageRenderer(
        theme: ProvidedThemes.lightTheme(logger: testLogger),
        scale: 4,
        logger: testLogger);
    final image = await renderer.render(tile, zoom: 16);
    final imageBytes = await image.toPng();
    final file = await writeTestFile(imageBytes, 'rendered-tile-zoom$zoom.png');
    final stat = await file.stat();
    expect(image.width, 1024);
    expect(image.height, 1024);
    expect(stat.size, isNonZero);
  }

  test('renders a vector tile', () async {
    final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
    final tile = VectorTileReader().read(bytes);
    await assertImageWith(tile, zoom: 25);
    await assertImageWith(tile, zoom: 16);
    await assertImageWith(tile, zoom: 10);
    await assertImageWith(tile, zoom: 2);
  });
}
