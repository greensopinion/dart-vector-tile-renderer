import 'dart:io';

import 'package:test/test.dart';
import 'package:tile_inator/src/layer_filter.dart';
import 'package:tile_inator/tile_inator.dart';

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
