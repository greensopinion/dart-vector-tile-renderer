import 'glyph_atlas_data.dart';

class AtlasProvider {
  final _loaded = <AtlasID, GlyphAtlas>{};

  AtlasProvider() {
    _instance = this;
  }

  void dispose() {
    _instance = null;
  }

  GlyphAtlas? getAtlasForString(String text, String? fontFamily) =>
      _loaded[_createPlaceholderId(fontFamily)];

  void addLoaded(GlyphAtlas atlas) {
    _loaded[atlas.id] = atlas;
  }

  //FIXME: this is no bueno
  static AtlasProvider? get instance => _instance;
  static AtlasProvider? _instance;
}

//FIXME: need to provide atlasses for character ranges beyond 256
AtlasID _createPlaceholderId(String? fontFamily) =>
    AtlasID(font: fontFamily ?? 'Roboto Regular', charStart: 0, charCount: 256);