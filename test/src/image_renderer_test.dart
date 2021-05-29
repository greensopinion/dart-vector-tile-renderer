import 'dart:io';

import 'package:dart_vector_tile_renderer/src/themes/outdoor_theme.dart';
import 'package:dart_vector_tile_renderer/src/themes/theme_reader.dart';
import 'package:test/test.dart';
import 'package:dart_vector_tile_renderer/src/image_renderer.dart';
import 'package:dart_vector_tile_renderer/src/vector_tile_reader.dart';
import 'package:dart_vector_tile_renderer/renderer.dart';

import 'test_files.dart';
import 'test_logger.dart';

void main() {
  test('renders a vector tile', () async {
    final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
    final tile = VectorTileReader().read(bytes);
    final renderer = ImageRenderer(
        theme: ThemeReader(testLogger).read(outdoorTheme()),
        scale: 4,
        logger: testLogger);
    final image = await renderer.render(tile);
    final imageBytes = await image.toPng();
    final file = await writeTestFile(imageBytes, 'tile.png');
    final stat = await file.stat();
    expect(image.width, 1024);
    expect(image.height, 1024);
    expect(stat.size, isNonZero);
  });
}
