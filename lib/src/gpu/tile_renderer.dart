import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../vector_tile_renderer.dart';
import '../logger.dart';
import '../themes/theme.dart';
import 'scene_building_visitor.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TileRenderer {
  static final Completer<void> _initializer = Completer<void>();
  static Future<void> initialize = _initializer.future;

  final GeometryWorkers geometryWorkers;

  final Logger logger;
  final Theme theme;
  final double zoom;
  TileSource? _tileSource;

  TileSource? get tileSource => _tileSource;
  set tileSource(TileSource? value) {
    if (_tileSource != value) {
      _tileSource = value;
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
        required this.geometryWorkers,
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
    final tileSource = _tileSource;
    if (tileSource == null) {
      return scene;
    }
    final context = VisitorContext(
      logger: logger,
      tileSource: tileSource,
      zoom: zoom,
    );
    SceneBuildingVisitor(scene, context, geometryWorkers).visitAllFeatures(theme);

    return scene;
  }
}

const int _maxTextureSize = 16384;
