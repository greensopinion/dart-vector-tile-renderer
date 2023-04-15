import 'dart:math';
import 'dart:ui';

import '../context.dart';
import '../../vector_tile_renderer.dart';

class IconRenderer {
  final Context context;
  final Sprite sprite;
  final Image atlas;

  IconRenderer(this.context, {required this.sprite, required this.atlas});

  Size render(Offset offset, {required Size contentSize}) {
    final paint = Paint()..isAntiAlias = true;

    double scale = (1 / (2 * sprite.pixelRatio));

    final segments = _fitContent(sprite, scale, contentSize: contentSize);
    if (segments.isNotEmpty) {
      double xOffset = (sprite.width * scale) / 2.0;
      double yOffset = (sprite.height * scale) / 2.0;
      context.canvas.drawAtlas(
          atlas,
          segments
              .map((e) => RSTransform.fromComponents(
                  rotation: 0,
                  scale: e.scale,
                  anchorX: 0,
                  anchorY: 0,
                  translateX: offset.dx - xOffset + e.centerOffset.dx,
                  translateY: offset.dy - yOffset + e.centerOffset.dy))
              .toList(),
          segments.map((e) => e.imageSource).toList(),
          null,
          null,
          null,
          paint);
      return segments
          .map((e) => e.imageSource.size * e.scale)
          .reduce((a, b) => Size(a.width + b.width, a.height + b.height));
    }
    return Size.zero;
  }

  List<_Segment> _fitContent(Sprite sprite, double scale,
      {required Size contentSize}) {
    double scaledWidth = scale * sprite.width;
    double scaledHeight = scale * sprite.height;
    final contentWidth = contentSize.width;
    final contentHeight = contentSize.height;
    if (contentWidth == 0 && contentWidth == 0 || sprite.content == null) {
      return [
        _Segment(
            imageSource: Rect.fromLTWH(sprite.x.toDouble(), sprite.y.toDouble(),
                sprite.width.toDouble(), sprite.height.toDouble()),
            centerOffset: Offset.zero,
            scale: scale)
      ];
    }
    //TODO: stretch with segments
    double margin = contentHeight / 4.0;
    double desiredHeight = contentHeight + 2 * margin;
    double desiredWidth = contentWidth + 2 * margin;
    double desiredScale =
        max(desiredWidth / sprite.width, desiredHeight / sprite.height);
    double actualWidth = desiredScale * sprite.width;
    double actualHeight = desiredScale * sprite.height;
    double offsetX = (scaledWidth - actualWidth) / 2.0;
    double offsetY = (scaledHeight - actualHeight) / 2.0;
    return [
      _Segment(
          imageSource: Rect.fromLTWH(sprite.x.toDouble(), sprite.y.toDouble(),
              sprite.width.toDouble(), sprite.height.toDouble()),
          centerOffset: Offset(offsetX, offsetY),
          scale: desiredScale)
    ];
  }
}

class _Segment {
  final Rect imageSource;
  final Offset centerOffset;
  final double scale;

  _Segment(
      {required this.imageSource,
      required this.centerOffset,
      required this.scale});
}
