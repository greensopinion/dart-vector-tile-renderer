import 'dart:typed_data';

import 'package:example/tile_painter.dart';
import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TileState();
  }
}

class _TileState extends State<Tile> {
  Uint8List? tileBytes;

  @override
  void initState() {
    super.initState();
    DefaultAssetBundle.of(context)
        .load('assets/sample_tile.pbf')
        .then((tileData) {
      setState(() {
        this.tileBytes = tileData.buffer
            .asUint8List(tileData.offsetInBytes, tileData.lengthInBytes);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tileBytes == null) {
      return CircularProgressIndicator();
    }
    return Container(
        decoration: BoxDecoration(color: Colors.black45),
        child: CustomPaint(
          size: Size(512, 512),
          painter: TilePainter(tileBytes!, scale: 2),
        ));
  }
}
