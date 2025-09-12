import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/sdf_renderer.dart';
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

  final cellSize = ((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding;

  final renderFontSize = fontSize * config.renderScale;

  final metrics = List.generate(config.charCount, (i) => metricsExtractor.extractMetrics(
    i + config.charCodeStart, cellSize, cellSize,
  ));

  final sdfRenderer = SdfRenderer(config, renderFontSize + 120);

  final texture = sdfRenderer.renderToSDF(await glyphRenderer.renderGlyphs(metrics, renderFontSize));

  return GlyphAtlas(
    texture: texture,
    atlasWidth: (((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridCols,
    atlasHeight: (((fontSize * config.renderScale + 40) ~/ config.renderScale) + config.sdfPadding) * config.gridRows,
    cellWidth: cellSize,
    cellHeight:  cellSize,
    glyphMetrics: metrics,
    fontFamily: id.font,
    fontSize: fontSize + 0.0,
    colorFormat: 'grayscale',
    sdfRadius: config.sdfRadius,
    charCodeStart: config.charCodeStart,
    charCodeEnd: config.charCodeEnd - 1,
    gridCols: config.gridCols,
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
          color: const ui.Color(0x000000FF),
          fontWeight: ui.FontWeight.normal,
          letterSpacing: fontSize.toDouble() / 16
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

  Future<Uint8List> renderGlyphs(List<GlyphMetrics> metrics, int renderFontSize) async {

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final cellSize = renderFontSize + 120.0;

    final canvasSize = Offset(cellSize * config.gridCols, cellSize * config.gridRows);

    canvas.drawRect(
      Rect.fromPoints(Offset.zero, canvasSize),
      Paint()..color = Colors.white,
    );

    for (int charCode = config.charCodeStart; charCode < config.charCodeEnd; charCode++) {
      final col = (charCode - config.charCodeStart) % config.gridCols;
      final row = (charCode - config.charCodeStart) ~/ config.gridCols;

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(charCode),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: renderFontSize.toDouble(),
            color: Colors.black,
            fontWeight: FontWeight.w100,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final paddingLeft = (cellSize - textPainter.width) / 2;
      final paddingTop = (cellSize - textPainter.height) / 2;

      textPainter.paint(canvas, Offset(paddingLeft + (col * cellSize), paddingTop + (row * cellSize)));
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.dx.toInt(), canvasSize.dy.toInt());

    final result = await getBytes(image);

    picture.dispose();
    image.dispose();
    return result;
  }

  Future<Uint8List> getBytes(ui.Image image) async {
    final byteData = Uint8List(image.width * image.height * 4);
    final decoded = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))?.buffer.asUint8List();

    return decoded ?? byteData;
  }
}