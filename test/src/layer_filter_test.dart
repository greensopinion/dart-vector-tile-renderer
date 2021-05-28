import 'dart:io';

import 'package:test/test.dart';
import 'package:dart_vector_tile_renderer/src/layer_filter.dart';
import 'package:dart_vector_tile_renderer/renderer.dart';

import 'fakes.dart';

void main() {
  test('filters a layer', () async {
    final filter = LayerFilter.named(names: ['first', 'second']);
    final firstLayer = FakeVectorTileLayer('first');
    final secondLayer = FakeVectorTileLayer('second');
    final thirdLayer = FakeVectorTileLayer('third');
    expect(filter.matches(firstLayer), equals(true));
    expect(filter.matches(secondLayer), equals(true));
    expect(filter.matches(thirdLayer), equals(false));
  });
}
