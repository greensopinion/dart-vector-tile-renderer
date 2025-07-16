import 'dart:math';

import 'package:example/tile_painter.dart';
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
// import again due to shadowed class name
import 'package:vector_tile_renderer/src/model/tile_model.dart' as tile_model;
import 'dart:ui' as ui;

enum RenderMode { vector, raster }

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
  Tileset? tileset;
  final theme = ProvidedThemes.lightTheme(logger: const Logger.console());
  ui.Image? image;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    TileRenderer.initialize.then((_) {
      if (!_disposed) {
        setState(() {});
      }
    });
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
    final isRaster = widget.options.renderMode == RenderMode.raster;
    if (tileset == null || (isRaster && image == null)) {
      return const CircularProgressIndicator();
    }
    return Container(
        decoration: BoxDecoration(color: Colors.black45, border: Border.all()),
        child: isRaster
            ? RawImage(image: image!, width: widget.options.size.width, height: widget.options.size.height)
            : CustomPaint(
                size: widget.options.size,
                painter: TilePainter(tileset!, theme, options: widget.options),
              ));
  }

  void _loadTileset() async {
    tile_model.Tile tile = await loadTile('assets/11_325_699_openmaptiles.pbf');
    tile_model.Tile contour = await loadTile('assets/11_325_699_contour.pbf');
    final tileset =
        TilesetPreprocessor(theme).preprocess(Tileset({'openmaptiles': tile, 'contour': contour}), zoom: 14);
    setState(() {
      this.tileset = tileset;
    });
    _maybeLoadImage();
  }

  Future<tile_model.Tile> loadTile(String path) async {
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

  void _maybeLoadImage() async {
    if (widget.options.renderMode == RenderMode.raster && image == null && tileset != null) {
      final image = await ImageRenderer(theme: theme, scale: 2).render(TileSource(tileset: tileset!),
          zoom: widget.options.zoom, zoomScaleFactor: pow(2, widget.options.scale).toDouble());
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
