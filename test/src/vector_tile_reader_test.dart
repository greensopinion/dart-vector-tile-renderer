import 'dart:io';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/vector_tile_reader.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'extensions.dart';

void main() {
  test('reads a vector tile', () async {
    final bytes = await File('test_data/sample_tile.pbf').readAsBytes();
    final tile = VectorTileReader().read(bytes);
    expect(tile, isNotNull);
    expect(
        tile.layers.map((e) => e.name).toSet().toList().sorted(),
        equals([
          'aerodrome_label',
          'boundary',
          'building',
          'landcover',
          'landuse',
          'park',
          'place',
          'transportation',
          'transportation_name',
          'water',
          'waterway'
        ]));
    final parks = tile.layers.where((l) => l.name == 'park').toList();
    expect(parks.length, 1);
    expect(parks.first.features.map((f) => f.type).toSet().toList(),
        equals([VectorTileGeomType.POLYGON]));
  });
}
