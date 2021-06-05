import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class TilePainter extends CustomPainter {
  final Uint8List tileBytes;
  final int scale;
  TilePainter(this.tileBytes, {required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final tile = VectorTileReader().read(tileBytes);
    final theme = ProvidedThemes.lightTheme();
    canvas.save();
    canvas.scale(scale.toDouble(), scale.toDouble());
    Renderer(theme: theme).render(canvas, tile, zoomScaleFactor: 1.0, zoom: 15);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
