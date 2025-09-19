import 'glyph_atlas_data.dart';

class AtlasProvider {
  final _loaded = <AtlasID, GlyphAtlas>{};

  AtlasProvider() {
    _instance = this;
  }

  void dispose() {
    _instance = null;
  }

  AtlasSet? getAtlasSetForString(String text, String? fontFamily) {
    final font = fontFamily ?? 'Roboto Regular';
    final charCodes = text.codeUnits.toSet();

    final requiredAtlases = <GlyphAtlas>{};

    // Find all atlases that contain characters from the text
    for (final charCode in charCodes) {
      bool found = false;
      for (final atlas in _loaded.values) {
        if (atlas.fontFamily == font && atlas.atlasID.hasChar(charCode)) {
          requiredAtlases.add(atlas);
          found = true;
          break;
        }
      }
      if (!found) {
        return null; // Missing character, can't render this text
      }
    }

    return AtlasSet(requiredAtlases);
  }

  void addLoaded(GlyphAtlas atlas) {
    _loaded[atlas.id] = atlas;
  }

  //FIXME: this is no bueno
  static AtlasProvider? get instance => _instance;
  static AtlasProvider? _instance;

  bool isCharLoaded(String font, int charCode) => _loaded.keys.any((id) => id.font == font && id.hasChar(charCode));
}