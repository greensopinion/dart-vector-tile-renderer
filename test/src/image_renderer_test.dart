import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'package:tile_inator/src/image_renderer.dart';
import 'package:tile_inator/src/vector_tile_reader.dart';
import 'package:tile_inator/tile_inator.dart';

import 'test_files.dart';

void main() {
  test('renders a vector tile', () async {
    final size = 1024;
    final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
    final tile = VectorTileReader().read(bytes);
    final renderer = ImageRenderer(size: size);
    final image = await renderer.render(tile);
    expect(image.width, size);
    expect(image.height, size);
    final imageBytes = await image.toPng();
    final file = await writeTestFile(imageBytes, 'tile.png');
    final stat = await file.stat();
    expect(stat.size, isNonZero);
  });
}
