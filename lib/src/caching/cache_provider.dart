import 'dart:typed_data';
import 'dart:ui';

import '../tileset.dart';

/// Abstract interface for cache providers
abstract class CacheProvider {
  /// Gets cached data by key, returns null if not found
  Future<T?> get<T>(String key);
  
  /// Stores data in cache with the given key
  Future<void> put<T>(String key, T value);
  
  /// Removes an item from cache
  Future<void> remove(String key);
  
  /// Clears all cached data
  Future<void> clear();
  
  /// Gets cache statistics
  CacheStats getStats();
}

/// Cache statistics interface
abstract class CacheStats {
  int get hitCount;
  int get missCount; 
  int get evictionCount;
  double get hitRate;
  int get size;
  String toDisplayString();
}

/// Specialized cache provider for tiles
abstract class TileCacheProvider extends CacheProvider {
  /// Gets cached tileset by tile identity
  Future<Tileset?> getTileset(String tileId);
  
  /// Stores tileset in cache
  Future<void> putTileset(String tileId, Tileset tileset);
}

/// Specialized cache provider for images
abstract class ImageCacheProvider extends CacheProvider {
  /// Gets cached image by key
  Future<Image?> getImage(String key);
  
  /// Stores image in cache
  Future<void> putImage(String key, Image image);
}

/// Specialized cache provider for binary data
abstract class BinaryCacheProvider extends CacheProvider {
  /// Gets cached bytes by key
  Future<Uint8List?> getBytes(String key);
  
  /// Stores bytes in cache
  Future<void> putBytes(String key, Uint8List bytes);
}

/// Default cache statistics implementation
class DefaultCacheStats implements CacheStats {
  @override
  final int hitCount;
  
  @override
  final int missCount;
  
  @override 
  final int evictionCount;
  
  @override
  final int size;
  
  const DefaultCacheStats({
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
    required this.size,
  });
  
  @override
  double get hitRate {
    final total = hitCount + missCount;
    return total > 0 ? hitCount / total : 0.0;
  }
  
  @override
  String toDisplayString() {
    return 'CacheStats(size: $size, hits: $hitCount, misses: $missCount, '
           'evictions: $evictionCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}