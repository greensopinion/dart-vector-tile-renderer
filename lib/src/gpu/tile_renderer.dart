import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vector_tile_renderer/src/gpu/scene_building_visitor.dart';
import 'package:vector_tile_renderer/src/logger.dart';

import '../themes/theme.dart';
import '../tileset.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///

const int maxTextureSize = 16384;

class TileRenderer {
  static final Completer<void> _initializer = Completer<void>();
  static Future<void> initialize = _initializer.future;

  final Logger logger;
  final Theme theme;
  final double zoom;
  Tileset? _tileset;

  Tileset? get tileset => _tileset;
  set tileset(Tileset? value) {
    if (_tileset != value) {
      _tileset = value;
      _scene = null;
    }
  }

  Scene? _scene;

  final Camera _camera = PerspectiveCamera(
    fovRadiansY: math.pi / 2, // 90 degrees
    position: vm.Vector3(
        0, 0, -128), // Move camera back far enough to see the full object
    target: vm.Vector3(0, 0, 0), // Looking at the origin
    up: vm.Vector3(0, 1, 0),
  );

  TileRenderer(
      {required this.theme,
      required this.zoom,
      this.logger = const Logger.noop()}) {
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

  void render(ui.Canvas canvas, ui.Size size) {
    ui.Size canvasScale = getCanvasScale(canvas);
    canvas.scale(canvasScale.width, canvasScale.height);

    scene.render(_camera, canvas, viewport: ui.Offset.zero & canvas.getLocalClipBounds().size);
  }

  ui.Size getCanvasScale(ui.Canvas canvas) {
    ui.Size src = canvas.getLocalClipBounds().size;
    ui.Size dest = canvas.getDestinationClipBounds().size;

    final view = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = view.display.devicePixelRatio;

    final resultSize = ui.Size(dest.width * pixelRatio, dest.height * pixelRatio);
    final result = ui.Size(src.width / resultSize.width, src.height / resultSize.height);

    if (result.isFinite && resultSize.isFinite && resultSize.longestSide < maxTextureSize) {
      return result;
    } else {
      // scale to max size -1 for floating point safety
      return ui.Size(src.width / (maxTextureSize - 1), src.height / (maxTextureSize - 1));
    }
  }

  Scene _createScene() {
    Scene scene = Scene();
    scene.antiAliasingMode = AntiAliasingMode.msaa;
    final tileset = _tileset;
    if (tileset == null) {
      return scene;
    }
    final context = VisitorContext(
      logger: logger,
      tileset: tileset,
      zoom: zoom,
    );
    final visitor = SceneBuildingVisitor(scene, context);
    for (final layer in theme.layers) {
      layer.accept(context, visitor);
    }
    return scene;
  }
}
