import '../tileset.dart';
import '../themes/theme.dart';

/// Strategy interface for tile preprocessing operations
abstract class TilePreprocessingStrategy {
  /// Preprocesses a tileset according to the strategy implementation
  Future<Tileset> preprocess(Tileset tileset, Theme theme, {required double zoom});
  
  /// Gets the name of this preprocessing strategy
  String get name;
  
  /// Indicates whether this strategy is CPU intensive
  bool get isCpuIntensive;
}

/// Default preprocessing strategy that performs theme-based optimization
class ThemeBasedPreprocessingStrategy implements TilePreprocessingStrategy {
  final bool initializeGeometry;
  
  const ThemeBasedPreprocessingStrategy({this.initializeGeometry = false});
  
  @override
  Future<Tileset> preprocess(Tileset tileset, Theme theme, {required double zoom}) async {
    final preprocessor = TilesetPreprocessor(theme, initializeGeometry: initializeGeometry);
    return preprocessor.preprocess(tileset, zoom: zoom);
  }
  
  @override
  String get name => 'theme-based';
  
  @override
  bool get isCpuIntensive => initializeGeometry;
}

/// No-op preprocessing strategy that passes through the tileset unchanged
class PassthroughPreprocessingStrategy implements TilePreprocessingStrategy {
  const PassthroughPreprocessingStrategy();
  
  @override
  Future<Tileset> preprocess(Tileset tileset, Theme theme, {required double zoom}) async {
    return tileset;
  }
  
  @override
  String get name => 'passthrough';
  
  @override
  bool get isCpuIntensive => false;
}

/// Strategy that applies multiple preprocessing strategies in sequence
class CompositePreprocessingStrategy implements TilePreprocessingStrategy {
  final List<TilePreprocessingStrategy> strategies;
  
  const CompositePreprocessingStrategy(this.strategies);
  
  @override
  Future<Tileset> preprocess(Tileset tileset, Theme theme, {required double zoom}) async {
    var result = tileset;
    for (final strategy in strategies) {
      result = await strategy.preprocess(result, theme, zoom: zoom);
    }
    return result;
  }
  
  @override
  String get name => 'composite(${strategies.map((s) => s.name).join(', ')})';
  
  @override
  bool get isCpuIntensive => strategies.any((s) => s.isCpuIntensive);
}