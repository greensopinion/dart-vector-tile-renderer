import 'dart:math';

import 'package:example/tile.dart';
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vt;
import 'dart:ui' as ui;

class TilePainter extends CustomPainter {
  final vt.Tileset tileset;
  final vt.Theme theme;
  final TileOptions options;
  final ui.Image? image;
  TilePainter(this.tileset, this.theme, {required this.options, this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-options.xOffset, -options.yOffset);
    canvas.scale(options.scale, options.scale);
    if (options.renderMode == RenderMode.raster) {
      if (image != null) {
        canvas.scale(0.5, 0.5);
        canvas.drawImage(image!, Offset.zero, Paint());
      }
    } else {
      vt.Renderer(theme: theme).render(canvas, tileset,
          clip: Rect.fromLTWH(0, 0, size.width, size.height),
          zoomScaleFactor: pow(2, options.scale).toDouble(),
          zoom: options.zoom);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
