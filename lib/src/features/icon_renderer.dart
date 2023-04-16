import 'dart:math';
import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import 'symbol_icon.dart';

class IconRenderer extends SymbolIcon {
  final Context context;
  final Sprite sprite;
  final Image atlas;
  final double size;

  IconRenderer(this.context,
      {required this.sprite, required this.atlas, required this.size});

  @override
  bool get overlapsText => sprite.content != null;

  @override
  Rect? render(Offset offset, {required Size contentSize}) {
    final paint = Paint()..isAntiAlias = true;

    double scale = (1 / (2 * sprite.pixelRatio));

    final segments = _fitContent(sprite, scale, contentSize: contentSize);
    if (segments.isNotEmpty) {
      double approximateWidth = (sprite.width * scale);
      double approximateHeight = (sprite.height * scale);
      double xOffset = approximateWidth / 2.0;
      double yOffset = approximateHeight / 2.0;
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
      return Rect.fromLTWH(offset.dx - xOffset, offset.dy - yOffset,
          approximateWidth, approximateHeight);
    }
    return Rect.fromCenter(center: offset, width: 0, height: 0);
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
            scale: scale * size)
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
        scale *
        size;
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
