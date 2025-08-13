import 'package:flutter/cupertino.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/main/geometry_workers.dart';
import 'package:vector_tile_renderer/src/gpu/scene_building_visitor.dart';
import 'package:vector_tile_renderer/src/logger.dart';
import 'package:vector_tile_renderer/src/themes/theme.dart';
import 'package:vector_tile_renderer/src/tile_source.dart';
import 'package:vector_tile_renderer/src/tileset.dart';
import 'package:vector_tile_renderer/src/tileset_raster.dart';

/// Interface for tile data that can be rendered in a scene
abstract class SceneTileData {
  /// The theme to use for rendering this tile
  Theme get theme;
  
  /// The tileset containing vector tile data, null if not available
  Tileset? get tileset;
  
  /// The raster tileset containing raster tile data, null if not available
  RasterTileset? get rasterTileset;
  
  /// Whether this tile data has been disposed
  bool get disposed;
  
  /// Gets a unique key for this tile
  String key();
}

/// Interface for tile model management
abstract class SceneTileModelProvider {
  /// Gets the model data for a given tile, or null if not available
  SceneTileData? getModel(SceneTileIdentity tile);
}

/// Simple tile identity for scene rendering
class SceneTileIdentity {
  final int z;
  final int x; 
  final int y;
  
  const SceneTileIdentity(this.z, this.x, this.y);
  
  String key() => "z=$z,x=$x,y=$y";
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneTileIdentity && z == other.z && x == other.x && y == other.y;
      
  @override
  int get hashCode => Object.hash(z, x, y);
}

/// Manages scene nodes for vector tiles, handling lifecycle and updates
class SceneTileManager extends ChangeNotifier {
  final Scene scene;
  final GeometryWorkers geometryWorkers = GeometryWorkers();
  final double Function() zoomProvider;

  final Map<String, Future<dynamic>> _inFlightTiles = {};
  final Set<Node> _forRemoval = {};


  SceneTileManager({
    required this.scene,
    required this.zoomProvider,
  });

  Future<void> updateTiles(List<SceneTileIdentity> tiles, SceneTileModelProvider modelProvider) async {

    return _updateTilesSynchronized(tiles, modelProvider);
  }

  /// Updates the scene with the given tiles, adding new ones and removing obsolete ones
  Future<void> _updateTilesSynchronized(List<SceneTileIdentity> tiles, SceneTileModelProvider modelProvider) async {
    final tileKeys = tiles.map((tile) => tile.key()).toSet();

    int newTiles = 0;

    // Remove nodes for tiles that are no longer visible
    for (final node in scene.root.children) {
      if (!tileKeys.contains(node.name)) {
        _forRemoval.add(node);
        _inFlightTiles.remove(node.name);
      }
    }
    
    // Add or update nodes for visible tiles
    for (final tile in tiles) {
      final model = modelProvider.getModel(tile);
      final existingNode = scene.root.children
          .where((node) => node.name == tile.key())
          .firstOrNull;

      _forRemoval.remove(existingNode);

      if (model != null && !model.disposed && model.tileset != null) {
        // Add node if it doesn't exist
        if (existingNode == null && !_inFlightTiles.keys.contains(tile.key())) {
          _inFlightTiles[tile.key()] = _createTileNode(tile, model);
          newTiles++;
        }
      }
    }

    await Future.wait(_inFlightTiles.values);

    for (var node in _forRemoval.toSet()) {
      if (node.parent == scene.root && !tiles.any((it) => it.key() == node.name)) {
        scene.remove(node);
        _forRemoval.remove(node);
      }
    }

    if (newTiles > 0) {
      notifyListeners();
    }
  }
  
  Future<void> _createTileNode(SceneTileIdentity tile, SceneTileData model) async {
    final node = Node(name: tile.key());
    
    final visitorContext = VisitorContext(
      logger: const Logger.noop(),
      tileSource: TileSource(
        tileset: model.tileset!,
        rasterTileset: model.rasterTileset ?? const RasterTileset(tiles: {}),
      ),
      zoom: zoomProvider(),
    );

    final featureNode = Node();
    final symbolNode = Node();
    node.add(featureNode);
    node.add(symbolNode);

    await SceneBuildingVisitor(featureNode, symbolNode, visitorContext, geometryWorkers).visitAllFeatures(model.theme);

    if (_inFlightTiles.containsKey(tile.key())) {
      scene.add(node);
      _inFlightTiles.remove(tile.key());
    }
  }
}