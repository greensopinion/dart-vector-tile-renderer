import 'dart:ui';

/// A raster tile is an image with a corresponding scope defining the portion of
/// the image that is in scope for the tile.
class RasterTile {
  final Image image;
  final Rect scope;

  RasterTile({required this.image, required this.scope});
}

/// A raster tileset is a collection of raster tiles (images) by `'source'` ID,
/// as defined by the theme.
class RasterTileset {
  final Map<String, RasterTile> tiles;

  const RasterTileset({required this.tiles});

  void dispose() {
    for (var tile in tiles.values) {
      tile.image.dispose();
    }
  }
}
