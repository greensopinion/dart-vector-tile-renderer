import 'dart:math' as math;

const int formatVersion = 2;

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
  
  final int atlasWidth;
  final int atlasHeight;
  final int cellWidth;
  final int cellHeight;
  final List<GlyphMetrics> glyphMetrics;
  final String fontFamily;
  final double fontSize;
  final String colorFormat;
  final int sdfRadius;
  final int charCodeStart;
  final int charCodeEnd;
  final int gridCols;

  GlyphAtlas({
    required this.atlasWidth,
    required this.atlasHeight,
    required this.cellWidth,
    required this.cellHeight,
    required this.glyphMetrics,
    required this.fontFamily,
    required this.fontSize,
    required this.colorFormat,
    required this.sdfRadius,
    required this.charCodeStart,
    required this.charCodeEnd,
    required this.gridCols,
  });

  int get charCount => charCodeEnd - charCodeStart + 1;

  int get gridRows => (charCount / gridCols).ceil();

  AtlasID get id => AtlasID(font: fontFamily, charStart: charCodeStart, charCount: charCount);


  CharacterUV getCharacterUV(int charCode) {
    if (charCode < charCodeStart || charCode > charCodeEnd) {
      throw ArgumentError('Character code must be between $charCodeStart and $charCodeEnd');
    }
    
    final col = (charCode - charCodeStart) % gridCols;
    final row = (charCode - charCodeStart) ~/ gridCols;
    
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
  
  /// Calculate UV coordinates for a character based on its glyph metrics (TinySDF format)
  /// This provides more precise UV coordinates that account for the actual glyph bounds
  CharacterUV getCharacterUVFromMetrics(int charCode) {
    final metrics = getGlyphMetrics(charCode);
    if (metrics == null) {
      // Fallback to grid-based UV calculation
      return getCharacterUV(charCode);
    }
    
    final col = (charCode - charCodeStart) % gridCols;
    final row = (charCode - charCodeStart) ~/ gridCols;
    
    // Base cell position in the atlas
    final baseCellX = col * cellWidth;
    final baseCellY = row * cellHeight;
    
    // Calculate the actual glyph bounds within the cell using TinySDF format
    final glyphLeft = baseCellX + metrics.glyphLeft;
    final glyphTop = baseCellY + (metrics.height - metrics.glyphTop);
    final glyphRight = glyphLeft + metrics.glyphWidth;
    final glyphBottom = glyphTop + metrics.glyphHeight;
    
    // Ensure bounds stay within the cell (should already be correct with proper metrics)
    final clampedLeft = math.max(glyphLeft.toDouble(), baseCellX.toDouble());
    final clampedTop = math.max(glyphTop.toDouble(), baseCellY.toDouble());
    final clampedRight = math.min(glyphRight.toDouble(), (baseCellX + cellWidth).toDouble());
    final clampedBottom = math.min(glyphBottom.toDouble(), (baseCellY + cellHeight).toDouble());
    
    // Convert to UV coordinates (0.0 to 1.0)
    final u1 = clampedLeft / atlasWidth;
    final v1 = clampedTop / atlasHeight;
    final u2 = clampedRight / atlasWidth;
    final v2 = clampedBottom / atlasHeight;
    
    return CharacterUV(u1: u1, v1: v1, u2: u2, v2: v2);
  }
  
  GlyphMetrics? getGlyphMetrics(int charCode) {
    try {
      return glyphMetrics.firstWhere((metrics) => metrics.charCode == charCode);
    } catch (e) {
      return null;
    }
  }
}