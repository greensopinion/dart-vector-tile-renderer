import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/style.dart';
import 'extensions.dart';
import 'symbol_icon.dart';

class IconRenderer extends SymbolIcon {
  final Context context;
  final Sprite sprite;
  final Image atlas;
  final double size;
  final LayoutAnchor anchor;
  final RotationAlignment rotationAlignment;
  final double? rotate;

  IconRenderer(this.context,
      {required this.sprite,
      required this.atlas,
      required this.size,
      required this.anchor,
      required this.rotationAlignment,
      required this.rotate});

  @override
  RenderedIcon? render(Offset offset,
      {required Size contentSize, required bool withRotation}) {
    final paint = Paint()..isAntiAlias = true;

    double scale = sprite.pixelRatio == 1 ? 1 : (1 / (sprite.pixelRatio));

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
      var rotation =
          withRotation && rotationAlignment == RotationAlignment.viewport
              ? context.rotation
              : 0.0;
      if (rotate != null) {
        rotation += (rotate! * pi / 180.0);
      }
      final anchorOffset = anchor.offset(renderedArea.size);
      if (rotation != 0.0) {
        context.canvas.save();
        final rotationOffset = Offset(
            offset.dx + anchorOffset.dx + (renderedArea.width / 2.0),
            offset.dy + anchorOffset.dy + (renderedArea.height / 2.0));
        context.canvas.translate(rotationOffset.dx, rotationOffset.dy);
        context.canvas.rotate(-rotation);
        context.canvas.translate(-rotationOffset.dx, -rotationOffset.dy);
      }
      context.canvas.drawAtlas(
          atlas,
          segments
              .map((e) => RSTransform.fromComponents(
                  rotation: 0.0,
                  scale: e.scale,
                  anchorX:
                      0, // rotation == 0.0 ? 0 : offset.dx + anchorOffset.dx,
                  anchorY:
                      0, //rotation == 0.0 ? 0 : offset.dy + anchorOffset.dy,
                  translateX: offset.dx + anchorOffset.dx,
                  translateY: offset.dy + anchorOffset.dy))
              .toList(),
          segments.map((e) => e.imageSource).toList(),
          null,
          null,
          null,
          paint);
      if (rotation != 0.0) {
        context.canvas.restore();
      }
      return RenderedIcon(
          overlapsText: sprite.content != null,
          area: renderedArea,
          contentArea: contentArea);
    }
    return null;
  }

  List<_Segment> _fitContent(Sprite sprite, double scale,
      {required Size contentSize}) {
    final completeSpriteSource = Rect.fromLTWH(sprite.x.toDouble(),
        sprite.y.toDouble(), sprite.width.toDouble(), sprite.height.toDouble());
    var spriteContent = sprite.content;
    var adjustedScale = scale * size;
    if (context.zoomScaleFactor > 1.0) {
      adjustedScale = adjustedScale / context.zoomScaleFactor;
    }
    if (spriteContent == null || contentSize == Size.zero) {
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
    final contentWidth = contentSize.width;
    final contentHeight = contentSize.height;
    double margin = contentHeight / 2;
    if (context.zoomScaleFactor > 1.0) {
      margin = margin * context.zoomScaleFactor;
    }
    double spriteContentWidth =
        (spriteContent[2] - spriteContent[0]).toDouble();
    double spriteContentHeight =
        (spriteContent[3] - spriteContent[1]).toDouble();
    double desiredContentWidth = contentWidth + (2 * margin);
    double desiredContentHeight = contentHeight + (2 * margin);
    double desiredScale = max(desiredContentWidth / spriteContentWidth,
            desiredContentHeight / spriteContentHeight) *
        adjustedScale;
    double actualWidth = (desiredScale * sprite.width);
    double actualHeight = (desiredScale * sprite.height);
    final actualContentArea = Rect.fromLTRB(
        spriteContent[0] * desiredScale,
        spriteContent[1] * desiredScale,
        spriteContent[2] * desiredScale,
        spriteContent[3] * desiredScale);
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
