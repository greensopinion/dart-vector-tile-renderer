import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  test('provides a renderer', () {
    expect(Renderer, isNotNull);
  });
  test('provides themes', () {
    expect(Theme, isNotNull);
    expect(ProvidedThemes, isNotNull);
    expect(ThemeReader, isNotNull);
  });
}
