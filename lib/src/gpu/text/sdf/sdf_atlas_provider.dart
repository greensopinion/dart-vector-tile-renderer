import 'glyph_atlas_data.dart';

abstract class SdfAtlasProvider {
  GlyphAtlas? getAtlasForString(String text, String? fontFamily);
}
