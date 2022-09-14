import 'dart:ui';

import '../../vector_tile_renderer.dart';

class TileSpaceMapper {
  TileSpaceMapper(
    Canvas canvas,
    Rect tileClip,
    int tileSize,
    int tileExtent,
  ) : this._(canvas, tileClip, 1 / tileExtent * tileSize);

  TileSpaceMapper._(
    this.canvas,
    Rect tileClip,
    this.pixelsPerTileUnit,
  ) : tileClipInTileUnits = tileClip.topLeft / pixelsPerTileUnit &
            tileClip.size / pixelsPerTileUnit;

  final Canvas canvas;
  final double pixelsPerTileUnit;
  final Rect tileClipInTileUnits;

  double widthFromPixelToTile(double value) {
    return value / pixelsPerTileUnit;
  }

  Offset pointFromTileToPixels(Offset point) {
    return point * pixelsPerTileUnit;
  }

  bool isPathWithinTileClip(BoundedPath path) {
    return tileClipInTileUnits.overlaps(path.bounds);
  }

  void drawInTileSpace(void Function() fn) {
    canvas.save();
    canvas.scale(pixelsPerTileUnit);
    fn();
    canvas.restore();
  }

  void drawInPixelSpace(void Function() fn) {
    canvas.save();
    canvas.scale(1 / pixelsPerTileUnit);
    fn();
    canvas.restore();
  }
}
