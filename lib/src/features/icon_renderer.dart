import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'extensions.dart';
import '../themes/style.dart';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import 'symbol_icon.dart';

class IconRenderer extends SymbolIcon {
  final Context context;
  final Sprite sprite;
  final Image atlas;
  final double size;
  final LayoutAnchor anchor;
  final double? rotate;

  IconRenderer(this.context,
      {required this.sprite,
      required this.atlas,
      required this.size,
      required this.anchor,
      required this.rotate});

  bool get overlapsText => sprite.content != null;

  @override
  RenderedIcon? render(Offset offset, {required Size contentSize}) {
    final paint = Paint()..isAntiAlias = true;

    double scale = (1 / (2 * sprite.pixelRatio));

    final segments = _fitContent(sprite, scale, contentSize: contentSize);
    if (segments.isNotEmpty) {
      final renderedArea = segments
          .map((e) => e.area.translate(offset.dx, offset.dy))
          .reduce((a, b) => a.expandToInclude(b));
      final contentArea = segments
              .map((e) => e.contentArea)
              .whereNotNull()
              .firstOrNull
              ?.translate(renderedArea.left, renderedArea.top) ??
          renderedArea;
      final anchorOffset = anchor.offset(renderedArea.size);
      context.canvas.drawAtlas(
          atlas,
          segments
              .map((e) => RSTransform.fromComponents(
                  rotation: rotate == null ? 0 : (rotate! * pi / 180.0),
                  scale: e.scale,
                  anchorX: rotate == null ? 0 : offset.dx + anchorOffset.dx,
                  anchorY: rotate == null ? 0 : offset.dy + anchorOffset.dy,
                  translateX: offset.dx + anchorOffset.dx,
                  translateY: offset.dy + anchorOffset.dy))
              .toList(),
          segments.map((e) => e.imageSource).toList(),
          null,
          null,
          null,
          paint);
      return RenderedIcon(
          overlapsText: overlapsText,
          area: renderedArea,
          contentArea: contentArea);
    }
    return null;
  }

  List<_Segment> _fitContent(Sprite sprite, double scale,
      {required Size contentSize}) {
    double scaledWidth = scale * sprite.width;
    double scaledHeight = scale * sprite.height;
    final contentWidth = contentSize.width;
    final contentHeight = contentSize.height;
    final completeSpriteSource = Rect.fromLTWH(sprite.x.toDouble(),
        sprite.y.toDouble(), sprite.width.toDouble(), sprite.height.toDouble());
    if ((contentWidth == 0 && contentWidth == 0) || sprite.content == null) {
      final adjustedScale = scale * size;
      return [
        _Segment(
            imageSource: completeSpriteSource,
            scale: adjustedScale,
            area: Rect.fromLTWH(
                0,
                0,
                completeSpriteSource.width * adjustedScale,
                completeSpriteSource.height * adjustedScale),
            contentArea: null)
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
    final center = Offset(offsetX, offsetY);
    final actualContentArea = Rect.fromLTRB(
        sprite.content![0] * desiredScale,
        sprite.content![1] * desiredScale,
        sprite.content![2] * desiredScale,
        sprite.content![3] * desiredScale);
    final actualArea = Rect.fromLTWH(0, 0, actualWidth, actualHeight);
    return [
      _Segment(
          imageSource: completeSpriteSource,
          scale: desiredScale,
          area: actualArea,
          contentArea: actualContentArea)
    ];
  }
}

class _Segment {
  final Rect imageSource;
  final double scale;
  final Rect area;
  final Rect? contentArea;

  _Segment(
      {required this.imageSource,
      required this.scale,
      required this.area,
      required this.contentArea});
}
