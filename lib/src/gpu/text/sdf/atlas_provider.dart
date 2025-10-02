import 'package:collection/collection.dart';

import 'glyph_atlas_data.dart';

class AtlasProvider {
  final _loaded = <String, Set<GlyphAtlas>>{};

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
    for (final key in keysToUnload) {
      _loaded.remove(key);
    }
    return _loaded.values.flattenedToSet;
  }
}