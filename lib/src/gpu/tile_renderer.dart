import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart' as m;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../themes/theme.dart';
import '../tileset.dart';
import 'color_extension.dart';
import 'shaders.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TileRenderer {
  static final Completer<void> _initializer = Completer<void>();
  static Future<void> initialize = _initializer.future;

  final Theme theme;
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

  TileRenderer({required this.theme}) {
    if (!_initializer.isCompleted) {
      Scene.initializeStaticResources().then((_) {
        _initializer.complete();
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
    scene.render(_camera, canvas, viewport: const ui.Offset(0, 0) & size);
  }

  Scene _createScene() {
    Scene scene = Scene();
    final mesh = Mesh(CuboidGeometry(vm.Vector3(256, 256, 0)), UnlitMaterial());
    scene.addMesh(mesh);
    return scene;
  }
}
