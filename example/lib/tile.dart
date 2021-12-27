import 'package:example/tile_painter.dart';
import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class Tile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TileState();
  }
}

class _TileState extends State<Tile> {
  Tileset? tileset;
  final theme = ProvidedThemes.lightTheme();

  @override
  void initState() {
    super.initState();
    _loadTileset();
  }

  @override
  Widget build(BuildContext context) {
    if (tileset == null) {
      return CircularProgressIndicator();
    }
    return Container(
        decoration: BoxDecoration(color: Colors.black45),
        child: CustomPaint(
          size: Size(512, 512),
          painter: TilePainter(tileset!, theme, scale: 2),
        ));
  }

  void _loadTileset() async {
    final tileData =
        await DefaultAssetBundle.of(context).load('assets/sample_tile.pbf');
    final tileBytes = tileData.buffer
        .asUint8List(tileData.offsetInBytes, tileData.lengthInBytes);
    final tile = VectorTileReader().read(tileBytes);
    final tileset =
        TilesetPreprocessor(theme).preprocess(Tileset({'openmaptiles': tile}));
    setState(() {
      this.tileset = tileset;
    });
  }
}
