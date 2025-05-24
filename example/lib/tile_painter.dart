import 'dart:math';

import 'package:example/tile.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';

class TilePainter extends CustomPainter {
  final Tileset tileset;
  final Theme theme;
  final TileOptions options;
  final ui.Image? image;
  TilePainter(this.tileset, this.theme, {required this.options, this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final renderer = TileRenderer(theme: theme);
    renderer.tileset = tileset;
    renderer.render(canvas, size);
    renderer.dispose();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
