import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'test_files.dart';
import 'test_logger.dart';
import 'test_tile.dart';

void main() {
  Future<void> assertImageWith(VectorTile tile, {required double zoom}) async {
    final renderer = ImageRenderer(
        theme: ProvidedThemes.lightTheme(logger: testLogger),
        scale: 4,
        logger: testLogger);
    final image = await renderer.render(tile, zoom: zoom);
    final imageBytes = await image.toPng();
    final file = await writeTestFile(imageBytes, 'rendered-tile-zoom$zoom.png');
    final stat = await file.stat();
    expect(image.width, 1024);
    expect(image.height, 1024);
    expect(stat.size, isNonZero);
  }

  test('renders a vector tile', () async {
    final tile = await readTestTile();
    await assertImageWith(tile, zoom: 13);
    await assertImageWith(tile, zoom: 15);
    await assertImageWith(tile, zoom: 18);
  });
}
