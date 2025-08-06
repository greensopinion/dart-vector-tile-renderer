

import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class TilePositioningContext extends SceneRenderingContext {
  @override
  TilePositioner createTilePositioner(int zoom) => ExampleTilePositioner();
}

class ExampleTilePositioner extends TilePositioner {
  @override
  Offset calculateTileOffset(BaseTileIdentity tile) {
    return Offset.zero;
  }

  @override
  Matrix4 createTransformMatrix(BaseTileIdentity tile, Size canvasSize) {
    return Matrix4.identity();
  }

  @override
  Size get tileSize => const Size(256, 256);
}