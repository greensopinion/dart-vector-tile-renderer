import 'dart:convert';

import '../logger.dart';
import 'sprite.dart';

class SpriteIndexReader {
  final Logger logger;

  SpriteIndexReader({this.logger = const Logger.noop()});

  SpriteIndex read(Map<String, dynamic> json) {
    return SpriteIndex(Map.fromEntries(json.entries
        .map((e) => _readSprite(e))
        .nonNulls
        .map((e) => MapEntry(e.name, e))));
  }

  Sprite? _readSprite(MapEntry<String, dynamic> entry) {
    final json = entry.value;
    if (json is Map) {
      final width = json['width'];
      final height = json['height'];
      final x = json['x'];
      final y = json['y'];
      final pixelRatio = json['pixelRatio'];
      if (width is int &&
          height is int &&
          x is int &&
          y is int &&
          pixelRatio is num) {
        var stretchX = _readStretch(json['stretchX'], width);
        var stretchY = _readStretch(json['stretchY'], height);
        var content = _readContent(json);
        return Sprite(
            name: entry.key,
            width: width,
            height: height,
            x: x,
            y: y,
            pixelRatio: pixelRatio.toInt(),
            stretchX: stretchX,
            stretchY: stretchY,
            content: content);
      }
    }
    logger.log(() => 'unexpected sprite: ${jsonEncode(json)}');
    return null;
  }

  List<List<int>> _readStretch(stretch, int defaultStretch) {
    if (stretch == null || stretch is! List<List<int>>) {
      stretch = [
        [0, defaultStretch]
      ];
    }
    return stretch;
  }

  List<int>? _readContent(Map json) {
    var content = json['content'] ?? json['placeholder'];
    if (content is List) {
      content = content
          .map((e) => e is num ? e.toInt() : null)
          .whereType<int>()
          .toList();
      if (content.length != 4) {
        content = null;
      }
    } else {
      content = null;
    }
    return content;
  }
}
