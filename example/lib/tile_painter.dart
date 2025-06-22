import 'package:example/tile.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class TilePainter extends CustomPainter {
  final Tileset tileset;
  final Theme theme;
  final TileOptions options;
  late final TileRenderer _renderer;
  bool _readyChanged = false;
  TilePainter(this.tileset, this.theme, {required this.options}) {
    _renderer = TileRenderer(theme: theme);
    _renderer.tileset = tileset;
    TileRenderer.initialize.then((_) {
      _readyChanged = true;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    _readyChanged = false;
    _renderer.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => _readyChanged;
}
