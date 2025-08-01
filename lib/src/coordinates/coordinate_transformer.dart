import 'dart:ui';

/// Represents a tile coordinate in a tiling system
class TileCoordinate {
  final int z; // zoom level
  final int x; // tile x coordinate  
  final int y; // tile y coordinate
  
  const TileCoordinate(this.z, this.x, this.y);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoordinate && z == other.z && x == other.x && y == other.y;
  
  @override
  int get hashCode => Object.hash(z, x, y);
  
  @override
  String toString() => 'TileCoordinate($z, $x, $y)';
}

/// Represents a translation between coordinate systems
class CoordinateTranslation {
  final TileCoordinate source;
  final TileCoordinate target;
  final double scale;
  final Offset offset;
  
  const CoordinateTranslation({
    required this.source,
    required this.target,  
    required this.scale,
    required this.offset,
  });
  
  @override
  String toString() => 'CoordinateTranslation($source -> $target, scale: $scale, offset: $offset)';
}

/// Abstract interface for coordinate system transformations
abstract class CoordinateTransformer {
  /// Transforms coordinates from one tile to another
  CoordinateTranslation transform(TileCoordinate from, TileCoordinate to);
  
  /// Gets the maximum zoom level supported by this transformer
  int get maximumZoom;
  
  /// Gets the tile size in pixels
  Size get tileSize;
  
  /// Checks if a tile coordinate is valid for this coordinate system
  bool isValidTile(TileCoordinate coordinate);
}

/// Default implementation for Web Mercator / Slippy Map coordinate system
class SlippyMapCoordinateTransformer implements CoordinateTransformer {
  @override
  final int maximumZoom;
  
  @override
  final Size tileSize;
  
  const SlippyMapCoordinateTransformer({
    this.maximumZoom = 18,
    this.tileSize = const Size(256, 256),
  });
  
  @override
  CoordinateTranslation transform(TileCoordinate from, TileCoordinate to) {
    final zoomDiff = to.z - from.z;
    final scale = 1.0 / (1 << zoomDiff); // 2^(-zoomDiff)
    
    final scaledFromX = from.x * scale;
    final scaledFromY = from.y * scale;
    
    final offsetX = (scaledFromX - to.x) * tileSize.width;
    final offsetY = (scaledFromY - to.y) * tileSize.height;
    
    return CoordinateTranslation(
      source: from,
      target: to,
      scale: scale,
      offset: Offset(offsetX, offsetY),
    );
  }
  
  @override
  bool isValidTile(TileCoordinate coordinate) {
    if (coordinate.z < 0 || coordinate.z > maximumZoom) return false;
    if (coordinate.x < 0 || coordinate.y < 0) return false;
    
    final maxTileIndex = 1 << coordinate.z; // 2^z
    return coordinate.x < maxTileIndex && coordinate.y < maxTileIndex;
  }
}