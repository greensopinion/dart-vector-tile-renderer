import 'dart:async';

import 'atlas_generator.dart';
import 'glyph_atlas_data.dart';
import 'sdf_atlas_provider.dart';

class SdfAtlasManager extends SdfAtlasProvider {
  final _loaded = <AtlasID, GlyphAtlas>{};
  final _loading = <AtlasID, Completer<GlyphAtlas>>{};

  @override
  GlyphAtlas? getAtlasForString(String text, String? fontFamily) =>
      _loaded[_createPlaceholderId(fontFamily)];

  Future loadAtlas(String str, String fontFamily) async {
    final chars = str.codeUnits;
    final (min, max) = _getBounds(chars);

    await _loadAtlas(_createPlaceholderId(fontFamily));
  }

  FutureOr<GlyphAtlas> _loadAtlas(AtlasID id) async {
    var atlas = _loading[id];
    if (atlas == null) {
      final completer = Completer<GlyphAtlas>();
      _loading[id] = completer;
      try {
        completer.complete(await generateBitmapAtlas(id, 24));
        final atlas = await completer.future;
        _loaded[id] = atlas;
      } catch (e) {
        completer.completeError(e);
      }
      atlas = completer;
    }
    return atlas.future;
  }

  (int, int) _getBounds(List<int> chars) {
    int minCode = 1000000000000;
    int maxCode = -1;

    for (int code in chars) {
      if (code < minCode) {
        minCode = code;
      }
      if (code > maxCode) {
        maxCode = code;
      }
    }
    maxCode++;
    return ((minCode / 256).truncate() * 256, (maxCode / 256).ceil() * 256);
  }
}

class AtlasID {
  final String font;
  final int charStart;
  final int charCount;

  const AtlasID(
      {required this.font, required this.charStart, required this.charCount});

  @override
  String toString() {
    return 'AtlasID{font: $font, charStart: $charStart, charCount: $charCount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtlasID &&
          runtimeType == other.runtimeType &&
          font == other.font &&
          charStart == other.charStart &&
          charCount == other.charCount;

  @override
  int get hashCode => Object.hash(font, charStart, charCount);
}

//FIXME: need to provide atlasses for character ranges beyond 256
AtlasID _createPlaceholderId(String? fontFamily) =>
    AtlasID(font: fontFamily ?? 'Roboto Regular', charStart: 0, charCount: 256);
