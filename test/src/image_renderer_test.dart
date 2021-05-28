import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'package:tile_inator/src/image_renderer.dart';
import 'package:tile_inator/src/vector_tile_reader.dart';
import 'package:tile_inator/tile_inator.dart';

import 'test_files.dart';
import 'test_logger.dart';

void main() {
  test('renders a vector tile', () async {
    final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
    final tile = VectorTileReader().read(bytes);
    final renderer = ImageRenderer(
        theme: LightTheme(),
        scale: 4,
        layerFilter: LayerFilter.named(names: ['water', 'waterway']),
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
