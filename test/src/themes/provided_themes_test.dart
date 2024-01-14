import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/provided_themes.dart';

void main() {
  test('provides a light theme', () {
    final theme = ProvidedThemes.lightTheme();
    expect(theme.id, 'osm-liberty');
    expect(theme.version, '2021-08-22');
    expect(theme.tileSources,
        <String>{'openmaptiles', 'natural_earth_shaded_relief'});
  });
}
