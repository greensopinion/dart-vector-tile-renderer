import 'dart:ui';

import 'package:flutter/material.dart' show TextPainter, TextSpan, TextStyle, TextAlign, TextDirection;

/// Service interface for text rendering operations
abstract class TextRenderingService {
  /// Gets or creates a text painter for the given configuration
  TextPainter getTextPainter(TextPainterConfiguration config);
  
  /// Measures text with the given configuration
  Size measureText(String text, TextPainterConfiguration config);
  
  /// Clears cached text painters
  void clearCache();
  
  /// Gets current cache statistics
  TextRenderingCacheStats getCacheStats();
}

/// Configuration for text painting
class TextPainterConfiguration {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double maxWidth;
  
  const TextPainterConfiguration({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.maxWidth = double.infinity,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextPainterConfiguration &&
          text == other.text &&
          style == other.style &&
          textAlign == other.textAlign &&
          textDirection == other.textDirection &&
          maxWidth == other.maxWidth;
  
  @override
  int get hashCode => Object.hash(text, style, textAlign, textDirection, maxWidth);
}

/// Statistics for text rendering cache
class TextRenderingCacheStats {
  final int cacheSize;
  final int hitCount;
  final int missCount;
  final double hitRate;
  
  const TextRenderingCacheStats({
    required this.cacheSize,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
  });
  
  @override
  String toString() {
    return 'TextRenderingCacheStats(size: $cacheSize, hits: $hitCount, misses: $missCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Default implementation using Flutter's TextPainter
class FlutterTextRenderingService implements TextRenderingService {
  final Map<TextPainterConfiguration, TextPainter> _cache = {};
  final int _maxCacheSize;
  int _hitCount = 0;
  int _missCount = 0;
  
  FlutterTextRenderingService({int maxCacheSize = 100}) : _maxCacheSize = maxCacheSize;
  
  @override
  TextPainter getTextPainter(TextPainterConfiguration config) {
    var painter = _cache[config];
    if (painter != null) {
      _hitCount++;
      return painter;
    }
    
    _missCount++;
    painter = TextPainter(
      text: TextSpan(text: config.text, style: config.style),
      textAlign: config.textAlign,
      textDirection: config.textDirection,
    );
    painter.layout(maxWidth: config.maxWidth);
    
    // Cache management
    if (_cache.length >= _maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    
    _cache[config] = painter;
    return painter;
  }
  
  @override
  Size measureText(String text, TextPainterConfiguration config) {
    final painter = getTextPainter(config);
    return painter.size;
  }
  
  @override
  void clearCache() {
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }
  
  @override
  TextRenderingCacheStats getCacheStats() {
    final total = _hitCount + _missCount;
    final hitRate = total > 0 ? _hitCount / total : 0.0;
    
    return TextRenderingCacheStats(
      cacheSize: _cache.length,
      hitCount: _hitCount,
      missCount: _missCount,
      hitRate: hitRate,
    );
  }
}