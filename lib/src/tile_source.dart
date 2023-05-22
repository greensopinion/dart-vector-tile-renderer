import 'dart:ui';

import 'themes/sprite.dart';
import 'tileset.dart';

/// a model representing the source data of a tile.
class TileSource {
  /// the tileset of the tile
  final Tileset tileset;

  /// The optional sprite index, which provides sprites referenced by the theme.
  /// If absent, sprites are ignored when rendering.
  final SpriteIndex? spriteIndex;

  /// The optional sprite atlas, which provides sprites referenced by the theme.
  /// If absent, sprites are ignored when rendering.
  final Image? spriteAtlas;

  TileSource({required this.tileset, this.spriteIndex, this.spriteAtlas});
}
