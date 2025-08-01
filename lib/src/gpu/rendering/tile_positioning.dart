import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vm;

/// Abstract interface for tile positioning calculations
abstract class TilePositioner {
  /// Creates a transformation matrix for positioning a tile in normalized device coordinates
  vm.Matrix4 createTransformMatrix(BaseTileIdentity tile, Size canvasSize);
  
  /// Calculates the pixel offset for a tile
  Offset calculateTileOffset(BaseTileIdentity tile);
  
  /// Gets the tile size in pixels
  Size get tileSize;
}

/// Default implementation for standard grid-based tile positioning
class GridBasedTilePositioner implements TilePositioner {
  final int tileZoom;
  final TilePositioningParameters parameters;
  
  const GridBasedTilePositioner(this.tileZoom, this.parameters);
  
  @override
  Size get tileSize => parameters.tileSize;
  
  @override
  vm.Matrix4 createTransformMatrix(BaseTileIdentity tile, Size canvasSize) {
    final offset = calculateTileOffset(tile);
    final toRight = calculateTileOffset(BaseTileIdentity(tile.z, tile.x + 1, tile.y));
    final toBottom = calculateTileOffset(BaseTileIdentity(tile.z, tile.x, tile.y + 1));

    final width = (toRight.dx - offset.dx);
    final height = (toBottom.dy - offset.dy);

    final centerX = offset.dx + width / 2.0;
    final centerY = offset.dy + height / 2.0;

    // Convert pixel center to normalized device coordinates (NDC)
    final ndcX = (centerX / canvasSize.width) * 2.0 - 1.0;
    final ndcY = 1.0 - (centerY / canvasSize.height) * 2.0;

    // Convert size to NDC scale
    final ndcScaleX = (width / canvasSize.width);
    final ndcScaleY = (height / canvasSize.height);

    return vm.Matrix4.identity()
      ..translate(ndcX, ndcY, 0.0)
      ..scale(ndcScaleX, ndcScaleY, 1.0);
  }
  
  @override
  Offset calculateTileOffset(BaseTileIdentity tile) {
    final tileOffset = Offset(
      tile.x.toDouble() * tileSize.width,
      tile.y.toDouble() * tileSize.height,
    );

    final tilePosition = (tileOffset - parameters.origin) * parameters.zoomScale + parameters.translate;
    return tilePosition;
  }
}

/// Parameters required for tile positioning calculations
class TilePositioningParameters {
  final double zoomScale;
  final Offset origin;
  final Offset translate;
  final Size tileSize;
  
  const TilePositioningParameters({
    required this.zoomScale,
    required this.origin,
    required this.translate,
    this.tileSize = const Size(256, 256),
  });
}

/// Tile identity for positioning calculations - lightweight data class
/// Note: In practice, this should be provided by the consumer of this library
class BaseTileIdentity {
  final int z, x, y;
  
  const BaseTileIdentity(this.z, this.x, this.y);
  
  @override
  String toString() => 'z:$z,x:$x,y:$y';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseTileIdentity && z == other.z && x == other.x && y == other.y;
  
  @override
  int get hashCode => Object.hash(z, x, y);
}