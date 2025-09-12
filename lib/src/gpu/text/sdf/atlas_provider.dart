import 'glyph_atlas_data.dart';

class AtlasProvider {
  final _loaded = <AtlasID, GlyphAtlas>{};

  GlyphAtlas? getAtlasForString(String text, String? fontFamily) =>
      _loaded[_createPlaceholderId(fontFamily)];

  void addLoaded(GlyphAtlas atlas) {
    _loaded[atlas.id] = atlas;
  }
}

//FIXME: need to provide atlasses for character ranges beyond 256
AtlasID _createPlaceholderId(String? fontFamily) =>
    AtlasID(font: fontFamily ?? 'Roboto Regular', charStart: 0, charCount: 256);