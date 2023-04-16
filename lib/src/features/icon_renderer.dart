import 'dart:math';
import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import 'symbol_icon.dart';

class IconRenderer extends SymbolIcon {
  final Context context;
  final Sprite sprite;
  final Image atlas;

  IconRenderer(this.context, {required this.sprite, required this.atlas});

  bool _isNotImplemented() => sprite.content == null;

  @override
  void render(Offset offset, {required Size contentSize}) {
    if (_isNotImplemented()) {
      return;
    }
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
    }
  }

  List<_Segment> _fitContent(Sprite sprite, double scale,
      {required Size contentSize}) {
    double scaledWidth = scale * sprite.width;
    double scaledHeight = scale * sprite.height;
    final contentWidth = contentSize.width;
    final contentHeight = contentSize.height;
    if ((contentWidth == 0 && contentWidth == 0) || sprite.content == null) {
      return [
        _Segment(
            imageSource: Rect.fromLTWH(sprite.x.toDouble(), sprite.y.toDouble(),
                sprite.width.toDouble(), sprite.height.toDouble()),
            centerOffset: Offset.zero,
            scale: scale)
      ];
    }
    double margin = contentHeight / 1.5;
    double spriteContentWidth =
        (sprite.content![2] - sprite.content![0]).toDouble();
    double spriteContentHeight =
        (sprite.content![3] - sprite.content![1]).toDouble();
    double desiredContentWidth = contentWidth + (2 * margin);
    double desiredContentHeight = contentHeight + (2 * margin);
    double desiredScale = max(desiredContentWidth / spriteContentWidth,
            desiredContentHeight / spriteContentHeight) *
        scale;
    double actualWidth = (desiredScale * sprite.width);
    double actualHeight = (desiredScale * sprite.height);
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
