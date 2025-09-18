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
    final neededIDs = AtlasID.iterableFromString(text: text, fontFamily: fontFamily);
    final atlases = neededIDs.map((id) => _loaded[id]);

    if (atlases.contains(null)) { return null; }
    return AtlasSet(<int, GlyphAtlas>{for (var v in atlases) v!.charCodeStart: v});
  }

  void addLoaded(GlyphAtlas atlas) {
    _loaded[atlas.id] = atlas;
  }

  //FIXME: this is no bueno
  static AtlasProvider? get instance => _instance;
  static AtlasProvider? _instance;
}