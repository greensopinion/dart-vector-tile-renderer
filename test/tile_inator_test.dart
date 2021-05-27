import 'package:test/test.dart';
import 'package:tile_inator/src/renderer.dart';

import 'package:tile_inator/tile_inator.dart';

void main() {
  test('provides a renderer', () {
    final renderer = Renderer();
    expect(renderer, isNotNull);
  });
}
