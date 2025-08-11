import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sdf_atlas_manager.dart';
import 'sdf_generator.dart';
import 'glyph_atlas_data.dart';

Future<GlyphAtlas> generateBitmapAtlas(
  AtlasID id, int fontSize
) async {
  final config = AtlasConfig(charCodeStart: id.charStart, charCount: id.charCount);

  // Initialize components
  final metricsExtractor = GlyphMetricsExtractor(fontFamily: id.font, fontSize: fontSize);
  final glyphRenderer = GlyphRenderer(fontFamily: id.font, config: config);
  final atlasBuilder = AtlasBuilder(config: config, fontSize: fontSize);

  final glyphMetricsList = <GlyphMetrics>[];

  // Process each character
  for (int charCode = config.charCodeStart; charCode < config.charCodeEnd; charCode++) {
    // Extract glyph metrics
    final metrics = metricsExtractor.extractMetrics(
      charCode,
      atlasBuilder.targetCellWidth,
      atlasBuilder.targetCellHeight,
    );
    glyphMetricsList.add(metrics);

    // Render glyph to SDF
    final renderedGlyph = await glyphRenderer.renderGlyph(charCode, metrics, fontSize);

    // Add to atlas
    atlasBuilder.addGlyph(renderedGlyph);
  }

  // Build final atlas
  return atlasBuilder.buildAtlas(
    fontFamily: id.font,
    fontSize: fontSize.toDouble(),
    glyphMetrics: glyphMetricsList,
  );
}


/// Configuration for atlas generation
class AtlasConfig {
  final int charCodeStart;
  final int charCount;
  late final int gridCols;
  late final int gridRows;
  final int sdfRadius;
  final int renderScale;
  final double sdfCutoff;
  final int sdfPadding;
  
  AtlasConfig({
    required this.charCodeStart,
    required this.charCount,
    this.sdfRadius = 32,
    this.renderScale = 4,
    this.sdfCutoff = 0.25,
    this.sdfPadding = 20,
  }) {
    gridCols = _getColumnCount(charCount);
    gridRows = _calculateRows(charCount, gridCols);
  }

  /// Calculate side length of smallest square with area >= [charCount] and power of 2 side lengths
  static int _getColumnCount(int charCount) {

    int exp = ((_log2(charCount) / 2) - 0.000001).ceil();
    return math.pow(2, exp) as int;
  }

  /// base 2 log function
  static double _log2(num num) => math.log(num) * _invLn2;

  /// 1 / ln(2)
  static const double _invLn2 = 1.442695040888963407359924681;

  /// Calculate number of rows needed for the given character count and columns
  static int _calculateRows(int charCount, int cols) {
    return (charCount / cols).ceil();
  }
  
  /// Get the end character code (exclusive)
  int get charCodeEnd => charCodeStart + charCount;
}

/// Result of rendering a single glyph
class RenderedGlyph {
  final GlyphMetrics metrics;
  final Uint8List sdfData;
  final int sdfSize;
  
  const RenderedGlyph({
    required this.metrics,
    required this.sdfData,
    required this.sdfSize,
  });
}

/// Responsible for extracting glyph metrics from text
class GlyphMetricsExtractor {
  final String fontFamily;
  final int fontSize;
  final ui.TextStyle _textStyle;
  
  GlyphMetricsExtractor({required this.fontFamily, required this.fontSize})
      : _textStyle = ui.TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize.toDouble(),
          color: const ui.Color(0xFFFFFFFF),
          fontWeight: ui.FontWeight.normal,
        );
  
  GlyphMetrics extractMetrics(int charCode, int targetCellWidth, int targetCellHeight) {
    final character = String.fromCharCode(charCode);
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontSize: fontSize.toDouble(),
    ));
    
    paragraphBuilder.pushStyle(_textStyle);
    paragraphBuilder.addText(character);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    
    GlyphMetrics metrics;
    try {
      if (paragraph.getGlyphInfoAt(0) case final glyphInfo?) {
        final glyphBounds = glyphInfo.graphemeClusterLayoutBounds;
        final baseline = paragraph.alphabeticBaseline;
        
        metrics = GlyphMetrics(
          charCode: charCode,
          width: targetCellWidth,
          height: targetCellHeight,
          glyphWidth: glyphBounds.width.round(),
          glyphHeight: glyphBounds.height.round(),
          glyphTop: (baseline - glyphBounds.top).round(),
          glyphLeft: math.max(0, ((targetCellWidth - glyphBounds.width) / 2).round()),
          glyphAdvance: glyphBounds.width,
        );
      } else {
        metrics = _createFallbackMetrics(charCode, targetCellWidth, targetCellHeight);
      }
    } catch (e) {
      metrics = _createFallbackMetrics(charCode, targetCellWidth, targetCellHeight);
    }
    
    paragraph.dispose();
    return metrics;
  }
  
  GlyphMetrics _createFallbackMetrics(int charCode, int targetCellWidth, int targetCellHeight) {
    final estimatedWidth = fontSize * 0.6;
    return GlyphMetrics(
      charCode: charCode,
      width: targetCellWidth,
      height: targetCellHeight,
      glyphWidth: estimatedWidth.round(),
      glyphHeight: fontSize,
      glyphTop: (fontSize * 0.8).round(),
      glyphLeft: ((targetCellWidth - estimatedWidth) / 2).round(),
      glyphAdvance: estimatedWidth,
    );
  }
}

/// Responsible for rendering individual glyphs and generating SDF
class GlyphRenderer {
  final String fontFamily;
  final AtlasConfig config;
  
  GlyphRenderer({required this.fontFamily, required this.config});
  
  Future<RenderedGlyph> renderGlyph(int charCode, GlyphMetrics metrics, int fontSize) async {
    final renderFontSize = fontSize * config.renderScale;
    final character = String.fromCharCode(charCode);
    
    // Calculate high-res buffer size
    final maxCharWidth = renderFontSize + 40;
    final maxCharHeight = renderFontSize + 40;
    final highResSdfSize = math.max(maxCharWidth + 80, maxCharHeight + 80);
    
    // Create text painter for high-resolution rendering
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: renderFontSize.toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Render to high-resolution canvas
    final sdfData = await _renderToSDF(textPainter, highResSdfSize);
    
    return RenderedGlyph(
      metrics: metrics,
      sdfData: sdfData,
      sdfSize: highResSdfSize,
    );
  }
  
  Future<Uint8List> _renderToSDF(TextPainter textPainter, int highResSdfSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Fill background with black
    canvas.drawRect(
      Rect.fromLTWH(0, 0, highResSdfSize.toDouble(), highResSdfSize.toDouble()),
      Paint()..color = Colors.black,
    );
    
    // Center the character
    final centerX = (highResSdfSize - textPainter.width) / 2;
    final centerY = (highResSdfSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(centerX, centerY));
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(highResSdfSize, highResSdfSize);
    
    // Extract pixel data and convert to SDF
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    
    Uint8List sdfData;
    if (byteData != null) {
      final rgbaPixels = byteData.buffer.asUint8List();
      final highResBuffer = Uint8List(highResSdfSize * highResSdfSize);
      
      // Convert RGBA to grayscale
      for (int i = 0; i < highResBuffer.length; i++) {
        final rgbaIndex = i * 4;
        highResBuffer[i] = rgbaPixels[rgbaIndex]; // Red channel
      }
      
      // Generate SDF
      sdfData = generateSDF(highResBuffer, highResSdfSize, highResSdfSize, config.sdfRadius, config.sdfCutoff);
    } else {
      sdfData = Uint8List(highResSdfSize * highResSdfSize);
    }
    
    // Clean up
    picture.dispose();
    image.dispose();
    
    return sdfData;
  }
}

/// Responsible for assembling rendered glyphs into the final atlas
class AtlasBuilder {
  final AtlasConfig config;
  final int targetCellWidth;
  final int targetCellHeight;
  final int atlasWidth;
  final int atlasHeight;
  final Uint8List _atlasData;
  
  AtlasBuilder({required this.config, required int fontSize}) :
    targetCellWidth = ((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding,
    targetCellHeight = ((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding,
    atlasWidth = (((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridCols,
    atlasHeight = (((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridRows,
    _atlasData = Uint8List((((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridCols * 
                          (((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridRows);
  
  void addGlyph(RenderedGlyph renderedGlyph) {
    final charCode = renderedGlyph.metrics.charCode;
    final relativeIndex = charCode - config.charCodeStart;
    final col = relativeIndex % config.gridCols;
    final row = relativeIndex ~/ config.gridCols;
    
    final startX = col * targetCellWidth;
    final startY = row * targetCellHeight;
    
    // Downsample the SDF to target resolution (4:1 ratio)
    for (int y = 0; y < targetCellHeight; y++) {
      for (int x = 0; x < targetCellWidth; x++) {
        final highResX = x * config.renderScale;
        final highResY = y * config.renderScale;
        
        int sum = 0;
        int count = 0;
        
        // Sample using box filter
        for (int dy = 0; dy < config.renderScale && (highResY + dy) < renderedGlyph.sdfSize; dy++) {
          for (int dx = 0; dx < config.renderScale && (highResX + dx) < renderedGlyph.sdfSize; dx++) {
            final sampleIndex = (highResY + dy) * renderedGlyph.sdfSize + (highResX + dx);
            if (sampleIndex < renderedGlyph.sdfData.length) {
              sum += renderedGlyph.sdfData[sampleIndex];
              count++;
            }
          }
        }
        
        final avgValue = count > 0 ? (sum / count).round() : 0;
        final dstX = startX + x;
        final dstY = startY + y;
        final dstIndex = dstY * atlasWidth + dstX;

        if (dstIndex < _atlasData.length) {
          _atlasData[dstIndex] = avgValue;
        }
      }
    }
  }
  
  GlyphAtlas buildAtlas({
    required String fontFamily,
    required double fontSize,
    required List<GlyphMetrics> glyphMetrics,
  }) {
    return GlyphAtlas(
      bitmapData: _atlasData,
      atlasWidth: atlasWidth,
      atlasHeight: atlasHeight,
      cellWidth: targetCellWidth,
      cellHeight: targetCellHeight,
      glyphMetrics: glyphMetrics,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colorFormat: 'grayscale',
      sdfRadius: config.sdfRadius,
      charCodeStart: config.charCodeStart,
      charCodeEnd: config.charCodeEnd - 1,
      gridCols: config.gridCols,
    );
  }
}