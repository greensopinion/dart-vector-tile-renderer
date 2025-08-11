
import 'dart:async';

import 'atlas_generator.dart';
import 'glyph_atlas_data.dart';

class SdfAtlasManager {
  final Map<AtlasID, Future<GlyphAtlas>> _loaded = {
    const AtlasID(font: "Roboto Regular", charStart: 0, charCount: 256): generateBitmapAtlas(const AtlasID(font: "Roboto Regular", charStart: 0, charCount: 256), 24)
  };

  FutureOr<GlyphAtlas> getAtlasForString(String str, String fontFamily) {
    final chars = str.codeUnits;
    final (min, max) = _getBounds(chars);

    return _getAtlas(AtlasID(font: fontFamily, charStart: min, charCount: max - min));
  }

  FutureOr<GlyphAtlas> _getAtlas(AtlasID id) {
    final atlas = _loaded[id];
    if (atlas == null) {
      print(id);
      final future = generateBitmapAtlas(id, 24);
      _loaded[id] = future;
      return future;
    } else {
      return atlas;
    }
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

  const AtlasID({required this.font, required this.charStart, required this.charCount});

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