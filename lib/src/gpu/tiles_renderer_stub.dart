// Web stub: GPU tiles renderer is unavailable on web.
// Provides API-compatible no-op classes so consuming code compiles for web.

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../tileset.dart';
import '../tileset_raster.dart';
import '../themes/theme.dart' show Theme;

class TileId {
  final int z;
  final int x;
  final int y;

  TileId({required this.z, required this.x, required this.y});

  @override
  String toString() => key();

  String key() => 'z=$z,x=$x,y=$y';
}

class TileUiModel {
  final TileId tileId;
  final ui.Rect position;
  final Tileset tileset;
  final RasterTileset rasterTileset;
  final Uint8List? renderData;

  TileUiModel({
    required this.tileId,
    required this.position,
    required this.tileset,
    required this.rasterTileset,
    this.renderData,
  });
}

class TilesRenderer {
  Theme theme;

  TilesRenderer(this.theme);

  static Future<void> initialize = Future.value();

  Uint8List Function(Theme theme, double zoom, Tileset tileset, String tileID)
      getPreRenderer() {
    return (Theme theme, double zoom, Tileset tileset, String tileID) =>
        Uint8List(0);
  }

  Future<void> preRenderUi(
      double zoom, Tileset tileset, String tileID) async {}

  void update(
      double zoom, List<TileUiModel> models, Iterable<String> tileIDs) {}

  void render(ui.Canvas canvas, ui.Size size, double rotation) {}

  void dispose() {}
}
