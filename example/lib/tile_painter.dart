import 'package:example/tile.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class TilePainter extends CustomPainter {
  final TileSource tileSource;
  final Theme theme;
  final TileOptions options;
  final GeometryWorkers geometryWorkers;
  late final TileRenderer _renderer;
  bool _readyChanged = false;
  TilePainter(this.tileSource, this.theme, this.geometryWorkers, {required this.options}) {
    _renderer = TileRenderer(
        theme: theme, logger: const Logger.console(), zoom: options.zoom, geometryWorkers: geometryWorkers);
    _renderer.tileSource = tileSource;
    TileRenderer.initialize.then((_) {
      _readyChanged = true;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    _readyChanged = false;
    _renderer.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => _readyChanged;
}
