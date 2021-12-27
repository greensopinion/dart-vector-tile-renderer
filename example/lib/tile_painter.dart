import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vt;

class TilePainter extends CustomPainter {
  final vt.Tileset tileset;
  final vt.Theme theme;
  final int scale;
  TilePainter(this.tileset, this.theme, {required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale.toDouble(), scale.toDouble());
    vt.Renderer(theme: theme).render(canvas, tileset,
        zoomScaleFactor: pow(2, scale).toDouble(), zoom: 15);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
