class AtlasSet {
  final Set<GlyphAtlas> _atlases;

  AtlasSet(this._atlases);

  double get fontSize => _atlases.first.fontSize;

  bool get isEmpty => _atlases.isEmpty;

  GlyphAtlas? getAtlasForChar(int charCode, String? font) {
    for (final atlas in _atlases) {
      if (atlas.fontFamily == (font ?? AtlasID._defaultFont) && atlas.atlasID.hasChar(charCode)) {
        return atlas;
      }
    }
    return null;
  }
}

class AtlasID {
  late final String font;

  final String chars;

  static const String _defaultFont = 'Roboto Regular';

  AtlasID({String? font, required this.chars}) {
    this.font = font ?? _defaultFont;
  }



  @override
  String toString() {
    return 'AtlasID{font: $font, chars: $chars}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AtlasID &&
              runtimeType == other.runtimeType &&
              font == other.font &&
              chars == other.chars;

  @override
  int get hashCode => Object.hash(font, chars);

  bool hasChar(int charCode) => chars.contains(String.fromCharCode(charCode));
}


class GlyphMetrics {
  final int charCode;
  final int width;          // Cell width (atlas cell dimensions)
  final int height;         // Cell height (atlas cell dimensions)
  final int glyphWidth;     // Actual glyph width
  final int glyphHeight;    // Actual glyph height
  final int glyphTop;       // Distance from baseline to top of glyph
  final int glyphLeft;      // Left offset within the cell
  final double glyphAdvance; // Horizontal advance (can be fractional)
  
  GlyphMetrics({
    required this.charCode,
    required this.width,
    required this.height,
    required this.glyphWidth,
    required this.glyphHeight,
    required this.glyphTop,
    required this.glyphLeft,
    required this.glyphAdvance,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'glyphWidth': glyphWidth,
      'glyphHeight': glyphHeight,
      'glyphTop': glyphTop,
      'glyphLeft': glyphLeft,
      'glyphAdvance': glyphAdvance,
    };
  }
  
  factory GlyphMetrics.fromJson(int charCode, Map<String, dynamic> json) {
    return GlyphMetrics(
      charCode: charCode,
      width: json['width'] as int,
      height: json['height'] as int,
      glyphWidth: json['glyphWidth'] as int,
      glyphHeight: json['glyphHeight'] as int,
      glyphTop: json['glyphTop'] as int,
      glyphLeft: json['glyphLeft'] as int,
      glyphAdvance: (json['glyphAdvance'] as num).toDouble(),
    );
  }
}

class CharacterUV {
  final double u1, v1, u2, v2;

  CharacterUV({
    required this.u1,
    required this.v1,
    required this.u2,
    required this.v2,
  });
}

class GlyphAtlas {

  final AtlasID atlasID;
  final int atlasWidth;
  final int atlasHeight;
  final int cellWidth;
  final int cellHeight;
  final Map<int, GlyphMetrics> glyphMetrics;
  final String fontFamily;
  final double fontSize;
  final String colorFormat;
  final int sdfRadius;
  final int gridCols;

  GlyphAtlas({
    required this.atlasID,
    required this.atlasWidth,
    required this.atlasHeight,
    required this.cellWidth,
    required this.cellHeight,
    required this.glyphMetrics,
    required this.fontFamily,
    required this.fontSize,
    required this.colorFormat,
    required this.sdfRadius,
    required this.gridCols,
  });

  int get charCount => glyphMetrics.length;

  int get gridRows => (charCount / gridCols).ceil();

  AtlasID get id => atlasID;


  CharacterUV getCharacterUV(int charCode) {
    final charIndex = atlasID.chars.codeUnits.indexOf(charCode);
    if (charIndex == -1) {
      throw ArgumentError('Character code $charCode not found in atlas');
    }

    final col = charIndex % gridCols;
    final row = charIndex ~/ gridCols;
    
    final x1 = col * cellWidth;
    final y1 = row * cellHeight;
    final x2 = x1 + cellWidth;
    final y2 = y1 + cellHeight;
    
    // Convert to UV coordinates (0.0 to 1.0)
    final u1 = x1 / atlasWidth;
    final v1 = y1 / atlasHeight;
    final u2 = x2 / atlasWidth;
    final v2 = y2 / atlasHeight;
    
    return CharacterUV(u1: u1, v1: v1, u2: u2, v2: v2);
  }
  
  GlyphMetrics? getGlyphMetrics(int charCode) => glyphMetrics[charCode];
}