import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../vector_tile_renderer.dart';
import 'concurrent/main/geometry_workers.dart';
import 'position_transform.dart';
import 'scene_building_visitor.dart';

class TileId {
  final int z;
  final int x;
  final int y;

  TileId({required this.z, required this.x, required this.y});
}

class TileUiModel {
  final TileId tileId;
  final Rect position;
  final Tileset tileset;
  final RasterTileset rasterTileset;

  TileUiModel(
      {required this.tileId,
      required this.position,
      required this.tileset,
      required this.rasterTileset});
}

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TilesRenderer {
  static final Completer<void> _initializer = Completer<void>();
  static Future<void> initialize = _initializer.future;

  final geometryWorkers = GeometryWorkers();

  final _positionByKey = <String, Rect>{};

  Scene? _scene;

  final Camera _camera = PerspectiveCamera(
    fovRadiansY: math.pi / 2, // 90 degrees
    position: vm.Vector3(
        0, 0, -128), // Move camera back far enough to see the full object
    target: vm.Vector3(0, 0, 0), // Looking at the origin
    up: vm.Vector3(0, 1, 0),
  );

  TilesRenderer() {
    if (!_initializer.isCompleted) {
      Scene.initializeStaticResources().then((_) {
        if (!_initializer.isCompleted) {
          _initializer.complete();
        }
      });
    }
  }

  Scene get scene {
    var scene = _scene;
    if (scene == null) {
      scene = _createScene();
      _scene = scene;
    }
    return scene;
  }

  void update(Theme theme, double zoom, List<TileUiModel> models) {
    final scene = this.scene;
    final nodesByKey =
        Map.fromEntries(scene.root.children.map((n) => MapEntry(n.name, n)));
    scene.root.removeAll();
    _positionByKey.clear();
    for (final model in models) {
      final key = 'tile-${model.tileId.z}-${model.tileId.x}-${model.tileId.y}';
      var node = nodesByKey[key];
      if (node == null) {
        node = Node(name: key);

        final visitorContext = VisitorContext(
          logger: const Logger.noop(),
          tileSource: TileSource(
              tileset: model.tileset, rasterTileset: model.rasterTileset),
          zoom: zoom,
        );

        SceneBuildingVisitor(node, visitorContext, geometryWorkers)
            .visitAllFeatures(theme);
      }
      _positionByKey[key] = model.position;
      scene.add(node);
    }
  }

  void render(ui.Canvas canvas, ui.Size size) {
    ui.Size canvasScale = getCanvasScale(canvas);
    canvas.scale(canvasScale.width, canvasScale.height);

    for (final node in scene.root.children) {
      final position = _positionByKey[node.name];
      if (position != null) {
        node.localTransform = tileTransformMatrix(position, size);
      }
    }
    scene.render(_camera, canvas,
        viewport: ui.Offset.zero & canvas.getLocalClipBounds().size);
  }

  ui.Size getCanvasScale(ui.Canvas canvas) {
    ui.Size src = canvas.getLocalClipBounds().size;
    ui.Size dest = canvas.getDestinationClipBounds().size;

    final view = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = view.display.devicePixelRatio;

    final resultSize =
        ui.Size(dest.width * pixelRatio, dest.height * pixelRatio);
    final result =
        ui.Size(src.width / resultSize.width, src.height / resultSize.height);

    if (result.isFinite &&
        resultSize.isFinite &&
        resultSize.longestSide < _maxTextureSize) {
      return result;
    } else {
      // scale to max size -1 for floating point safety
      return ui.Size(src.width / (_maxTextureSize - 1),
          src.height / (_maxTextureSize - 1));
    }
  }

  Scene _createScene() {
    Scene scene = Scene();
    scene.antiAliasingMode = AntiAliasingMode.msaa;
    return scene;
  }

  void dispose() {
    geometryWorkers.dispose();
  }
}

const int _maxTextureSize = 16384;
