import 'dart:math';

import 'package:example/tile_painter.dart';
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;

enum RenderMode { vector, raster }

class TileOptions {
  final Size size;
  final double scale;
  final double zoom;
  final double xOffset;
  final double yOffset;
  final RenderMode renderMode;
  final double clipOffset;
  final double clipSize;

  TileOptions(
      {required this.size,
      required this.scale,
      required this.zoom,
      required this.xOffset,
      required this.yOffset,
      required this.clipOffset,
      required this.clipSize,
      required this.renderMode});

  TileOptions withValues(
      {double? scale,
      Size? size,
      double? zoom,
      double? xOffset,
      double? yOffset,
      double? clipOffset,
      double? clipSize,
      RenderMode? renderMode}) {
    return TileOptions(
        size: size ?? this.size,
        scale: scale ?? this.scale,
        zoom: zoom ?? this.zoom,
        xOffset: xOffset ?? this.xOffset,
        yOffset: yOffset ?? this.yOffset,
        clipOffset: clipOffset ?? this.clipOffset,
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
  Tileset? tileset;
  final theme = ProvidedThemes.lightTheme(logger: Logger.console());
  ui.Image? image;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadTileset();
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    image?.dispose();
  }

  @override
  void didUpdateWidget(Tile tile) {
    super.didUpdateWidget(tile);
    image?.dispose();
    image = null;
    tileset = null;
    _loadTileset();
  }

  @override
  Widget build(BuildContext context) {
    if (tileset == null ||
        (widget.options.renderMode == RenderMode.raster && image == null)) {
      return CircularProgressIndicator();
    }
    return Container(
        decoration: BoxDecoration(color: Colors.black45, border: Border.all()),
        child: CustomPaint(
          size: widget.options.size,
          painter: TilePainter(tileset!, theme,
              options: widget.options, image: image),
        ));
  }

  void _loadTileset() async {
    final tileBuffer =
        await DefaultAssetBundle.of(context).load('assets/sample_tile.pbf');
    final tileBytes = tileBuffer.buffer
        .asUint8List(tileBuffer.offsetInBytes, tileBuffer.lengthInBytes);
    var tileData = TileFactory(theme, Logger.noop())
        .createTileData(VectorTileReader().read(tileBytes));
    if (widget.options.clipSize > 0) {
      final clipSize = widget.options.clipSize;
      final clipOffset = widget.options.clipOffset;
      final clip = TileClip(
          bounds: Rectangle(clipOffset, clipOffset, clipSize, clipSize));
      tileData = clip.clip(tileData);
      if (clipOffset > 0) {
        tileData =
            TileTranslate(Point(-clipOffset, -clipOffset)).translate(tileData);
      }
    }
    final tile = tileData.toTile();
    final tileset = TilesetPreprocessor(theme)
        .preprocess(Tileset({'openmaptiles': tile}), zoom: 14);
    setState(() {
      this.tileset = tileset;
    });
    _maybeLoadImage();
  }

  void _maybeLoadImage() async {
    if (widget.options.renderMode == RenderMode.raster &&
        image == null &&
        tileset != null) {
      final image = await ImageRenderer(theme: theme, scale: 2).render(tileset!,
          zoom: widget.options.zoom,
          zoomScaleFactor: pow(2, widget.options.scale).toDouble());
      if (_disposed) {
        image.dispose();
      } else {
        setState(() {
          this.image = image;
        });
      }
    }
  }
}
