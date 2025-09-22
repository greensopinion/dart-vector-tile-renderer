import 'package:collection/collection.dart';

import 'glyph_atlas_data.dart';

class AtlasProvider {
  final _loaded = <String, Set<GlyphAtlas>>{};

  AtlasProvider() {
    _instance = this;
  }

  void dispose() {
    _instance = null;
  }

  void addLoaded(Set<GlyphAtlas> atlases, String tileID) {
    final existing = _loaded[tileID];
    if (existing != null) {
      existing.addAll(atlases);
    } else {
      _loaded[tileID] = atlases;
    }
  }

  AtlasSet forTileID(String tileID) {
    return AtlasSet({}..addAll(_loaded[tileID] ?? {})..addAll(_loaded[""] ?? {}));
  }

  Set<GlyphAtlas> unload(String tileID) {
    final out = _loaded[tileID];
    _loaded.remove(tileID);
    return out ?? {};
  }

  Set<GlyphAtlas> unloadWhereNotFound(Set<String> tileIDs) {
    final keysToUnload = _loaded.keys.toSet().whereNot((it) => it.isEmpty || tileIDs.contains(it));
    final atlasesToUnload = keysToUnload.map((it) => _loaded[it]).nonNulls.flattenedToSet;
    for (final key in keysToUnload) {
      _loaded.remove(key);
    }
    return atlasesToUnload;
  }



  //FIXME: this is no bueno
  static AtlasProvider? get instance => _instance;
  static AtlasProvider? _instance;
}