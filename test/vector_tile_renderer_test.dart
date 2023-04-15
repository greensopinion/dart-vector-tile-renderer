import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  test('provides a renderer', () {
    expect(Renderer, isNotNull);
  });
  test('provides a model', () {
    expect(TileSource, isNotNull);
    expect(Tileset, isNotNull);
  });
  test('provides themes', () {
    expect(Theme, isNotNull);
    expect(ProvidedThemes, isNotNull);
    expect(ThemeReader, isNotNull);
  });
  test('provides sprites', () {
    expect(Sprite, isNotNull);
    expect(SpriteIndex, isNotNull);
    expect(SpriteIndexReader, isNotNull);
  });
}
