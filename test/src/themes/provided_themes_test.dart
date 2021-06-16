import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/provided_themes.dart';

void main() {
  test('provides a light theme', () {
    final theme = ProvidedThemes.lightTheme();
    expect(theme.id, 'osm-liberty');
  });
}
