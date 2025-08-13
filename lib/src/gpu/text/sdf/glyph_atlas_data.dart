import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter_gpu/gpu.dart';

const int formatVersion = 2;

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
  
  final Uint8List bitmapData;
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

  late final Texture texture = gpuContext.createTexture(StorageMode.hostVisible, atlasWidth, atlasHeight,
      format: PixelFormat.r8UNormInt);
  
  GlyphAtlas({
    required this.bitmapData,
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
  }) {
    texture.overwrite(bitmapData.buffer.asByteData());
  }
  
  /// Calculate the number of grid rows based on character range and grid columns
  int get gridRows => ((charCodeEnd - charCodeStart + 1) / gridCols).ceil();
  
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
  
  List<Map<String, dynamic>?> getGlyphsJson() {
    final glyphsArray = List<Map<String, dynamic>?>.filled(charCodeEnd - charCodeStart + 1, null);
    
    for (var metrics in glyphMetrics) {
      glyphsArray[metrics.charCode - charCodeStart] = metrics.toJson();
    }
    
    return glyphsArray;
  }
  
  /// Get full atlas info including metadata
  Map<String, dynamic> toJson() {
    return {
      'atlas': {
        'format_version': formatVersion, // Updated version to indicate TinySDF-compatible format
        'width': atlasWidth,
        'height': atlasHeight,
        'cellWidth': cellWidth,
        'cellHeight': cellHeight,
        'gridCols': gridCols,
        'gridRows': gridRows,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'colorFormat': colorFormat,
        'sdfRadius': sdfRadius,
        'charCodeStart': charCodeStart,
        'charCodeEnd': charCodeEnd,
      },
      'glyphs': getGlyphsJson(),
    };
  }
  
  /// Create a BitmapAtlas from JSON string
  static GlyphAtlas fromJson(String jsonString, Uint8List bitmapData) {
    final Map<String, dynamic> data = json.decode(jsonString);
    final Map<String, dynamic> atlasInfo = data['atlas'];
    final List<dynamic> glyphsData = data['glyphs'];
    
    // Validate format version
    final int formatVersion = atlasInfo['format_version'] as int;
    if (formatVersion != formatVersion) {
      throw FormatException(
        'Unsupported atlas format version: $formatVersion. Expected: $formatVersion'
      );
    }
    
    // Parse glyph metrics
    final List<GlyphMetrics> glyphMetrics = [];
    for (int i = 0; i < glyphsData.length; i++) {
      final glyphJson = glyphsData[i];
      if (glyphJson != null) {
        glyphMetrics.add(GlyphMetrics.fromJson(i + atlasInfo['charCodeStart'] as int, glyphJson as Map<String, dynamic>));
      }
    }
    
    return GlyphAtlas(
      bitmapData: bitmapData,
      atlasWidth: atlasInfo['width'] as int,
      atlasHeight: atlasInfo['height'] as int,
      cellWidth: atlasInfo['cellWidth'] as int,
      cellHeight: atlasInfo['cellHeight'] as int,
      glyphMetrics: glyphMetrics,
      fontFamily: atlasInfo['fontFamily'] as String,
      fontSize: (atlasInfo['fontSize'] as num).toDouble(),
      colorFormat: atlasInfo['colorFormat'] as String,
      sdfRadius: atlasInfo['sdfRadius'] as int,
      charCodeStart: atlasInfo['charCodeStart'] as int,
      charCodeEnd: atlasInfo['charCodeEnd'] as int,
      gridCols: atlasInfo['gridCols'] as int,
    );
  }
}