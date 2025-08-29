import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
// import again due to shadowed class name
import 'package:vector_tile_renderer/src/model/tile_model.dart' as tile_model;

enum RenderMode { shader, canvas }

class TileOptions {
  final Size size;
  final double scale;
  final double zoom;
  final double xOffset;
  final double yOffset;
  final RenderMode renderMode;
  final double clipOffsetX;
  final double clipOffsetY;
  final double clipSize;

  TileOptions(
      {required this.size,
      required this.scale,
      required this.zoom,
      required this.xOffset,
      required this.yOffset,
      required this.clipOffsetX,
      required this.clipOffsetY,
      required this.clipSize,
      required this.renderMode});

  TileOptions withValues(
      {double? scale,
      Size? size,
      double? zoom,
      double? xOffset,
      double? yOffset,
      double? clipOffsetX,
      double? clipOffsetY,
      double? clipSize,
      RenderMode? renderMode}) {
    return TileOptions(
        size: size ?? this.size,
        scale: scale ?? this.scale,
        zoom: zoom ?? this.zoom,
        xOffset: xOffset ?? this.xOffset,
        yOffset: yOffset ?? this.yOffset,
        clipOffsetX: clipOffsetX ?? this.clipOffsetX,
        clipOffsetY: clipOffsetY ?? this.clipOffsetY,
        clipSize: clipSize ?? this.clipSize,
        renderMode: renderMode ?? this.renderMode);
  }
}

class Tile extends StatefulWidget {
  final TileOptions options;

  const Tile({Key? key, required this.options}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TileState();
  }
}

class _TileState extends State<Tile> {
  final theme = ProvidedThemes.lightTheme(logger: const Logger.console());
  bool _disposed = false;
  late Tileset _tileset;

  final TilesRenderer gpuRenderer = TilesRenderer();
  late final Renderer canvasRenderer = Renderer(theme: theme);

  double get zoom => widget.options.zoom;


  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    _tileset = await _loadTileset();

    if (!_disposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    switch(widget.options.renderMode) {
      case RenderMode.shader:
        return buildGpu();
      case RenderMode.canvas:
        return buildCanvas();
    }
  }

  Container buildGpu() {
    final options = widget.options;
    final position = Rect.fromLTWH(options.xOffset, options.yOffset, options.size.width, options.size.height);

    final model = TileUiModel(
      tileId: TileId(z: zoom.truncate(), x: 0, y: 0),
      position: position, tileset: _tileset,
      rasterTileset: const RasterTileset(tiles: {}),
      renderData: TilesRenderer.preRender((theme, zoom, _tileset)),
    );

    gpuRenderer.update(theme, zoom, [model]);

    return Container(
        constraints: BoxConstraints(maxWidth: widget.options.size.width, maxHeight: widget.options.size.height),
        child: Stack(children: [
          SizedBox.expand(child: CustomPaint(painter: GpuTilePainter(gpuRenderer))),
          Container(decoration: BoxDecoration(border: Border.all()))
        ]));
  }

  Container buildCanvas() {
    return Container(
        constraints: BoxConstraints(maxWidth: widget.options.size.width, maxHeight: widget.options.size.height),
        child: Stack(children: [
          SizedBox.expand(child: CustomPaint(painter: CanvasTilePainter(canvasRenderer, widget.options, _tileset))),
          Container(decoration: BoxDecoration(border: Border.all()))
        ]));
  }

  Future<Tileset> _loadTileset() async {
    tile_model.Tile tile = await loadVectorTile('assets/sample_tile.pbf');
    return Tileset({'openmaptiles': tile});
  }

  Future<tile_model.Tile> loadVectorTile(String path) async {
    final tileBuffer = await DefaultAssetBundle.of(context).load(path);
    final tileBytes = tileBuffer.buffer.asUint8List(tileBuffer.offsetInBytes, tileBuffer.lengthInBytes);
    var tileData = TileFactory(theme, const Logger.noop()).createTileData(VectorTileReader().read(tileBytes));
    if (widget.options.clipSize > 0) {
      final clipSize = widget.options.clipSize;
      final clipOffsetX = widget.options.clipOffsetX;
      final clipOffsetY = widget.options.clipOffsetY;
      final clip = TileClip(bounds: Rectangle(clipOffsetX, clipOffsetY, clipSize, clipSize));
      tileData = clip.clip(tileData);
      if (clipOffsetX > 0 || clipOffsetY > 0) {
        tileData = TileTranslate(Point(-clipOffsetX, -clipOffsetY)).translate(tileData);
      }
    }
    return tileData.toTile();
  }
}

class GpuTilePainter extends CustomPainter{
  final TilesRenderer renderer;

  GpuTilePainter(this.renderer);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    renderer.render(canvas, size, 0.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class CanvasTilePainter extends CustomPainter{
  final Renderer renderer;
  final TileOptions options;
  final Tileset tileset;

  CanvasTilePainter(this.renderer, this.options, this.tileset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final scale = size.width / 256.0;
    canvas.scale(scale);

    renderer.render(canvas, TileSource(tileset: tileset), zoomScaleFactor: scale, zoom: options.zoom, rotation: 0.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}