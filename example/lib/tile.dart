import 'dart:math';

import 'package:example/tile_model_provider.dart';
import 'package:example/tile_positioner.dart';
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
// import again due to shadowed class name
import 'package:vector_tile_renderer/src/model/tile_model.dart' as tile_model;

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
  final theme = ProvidedThemes.lightTheme(logger: const Logger.console());
  bool _disposed = false;

  VectorSceneRenderer renderer = VectorSceneRenderer(context: TilePositioningContext());

  late final sceneTileManager = SceneTileManager(
    scene: renderer.scene,
    zoomProvider: () => zoom,
  );

  double get zoom => widget.options.zoom;


  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final tileset = await _loadTileset();

    await sceneTileManager.updateTiles(
        [const SceneTileIdentity(0, 0, 0)],
        ExampleTileModelProvider(tileset, theme)
    );

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

    return Container(
        decoration: BoxDecoration(color: Colors.black45, border: Border.all()),
        constraints: BoxConstraints(maxWidth: widget.options.size.width, maxHeight: widget.options.size.height),
        child: renderer
    );
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

  // Future<RasterTile> loadRasterTile(String path) async {
  //   final tileBuffer = await DefaultAssetBundle.of(context).load(path);
  //   final Uint8List bytes = tileBuffer.buffer.asUint8List();
  //
  //   final image = await decodeImageFromList(bytes.buffer.asUint8List());
  //   return RasterTile(image: image, scope: const Rect.fromLTRB(0, 0, 256, 256));
  // }
  //
  // void _maybeLoadImage() async {
  //   if (widget.options.renderMode == RenderMode.raster && image == null && tileSource != null) {
  //     final image = await ImageRenderer(theme: theme, scale: 2).render(tileSource!,
  //         zoom: widget.options.zoom, zoomScaleFactor: pow(2, widget.options.scale).toDouble());
  //     if (_disposed) {
  //       image.dispose();
  //     } else {
  //       setState(() {
  //         this.image = image;
  //       });
  //     }
  //   }
  // }
}
