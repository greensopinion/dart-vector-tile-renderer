import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vector_tile_renderer/src/gpu/rendering/orthographic_camera.dart';
import 'package:vector_tile_renderer/src/gpu/rendering/scene_tile_manager.dart';

import 'tile_positioning.dart';

/// A Flutter widget that renders a flutter_scene Scene with proper tile positioning
class VectorSceneRenderer extends StatefulWidget {
  final Scene _scene = Scene();
  final SceneRenderingContext context;
  late final SceneTileManager sceneTileManager = SceneTileManager(scene: _scene, zoomProvider: () => context.zoom);

  VectorSceneRenderer({
    super.key, 
    required this.context,
  });

  @override
  VectorSceneRendererState createState() => VectorSceneRendererState();
}

class VectorSceneRendererState extends State<VectorSceneRenderer> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: VectorScenePainter(widget._scene, widget.context),
      child: const SizedBox.expand(),
    );
  }
}

/// Custom painter that handles the actual scene rendering with tile positioning
class VectorScenePainter extends CustomPainter {
  final Scene _scene;
  final SceneRenderingContext renderingContext;
  
  VectorScenePainter(this._scene, this.renderingContext);

  @override
  void paint(Canvas canvas, Size size) {

    // Clip canvas if not clipped already
    if (canvas.getLocalClipBounds().width > 1000000) {
      canvas.clipRect(ui.Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    }

    // Apply tile transforms to all nodes in the scene
    _scene.root.children.forEach((Node node) {
      final tileId = TileNodeUtils.parseFromNodeName(node.name);
      if (tileId != null) {
        final positioner = renderingContext.createTilePositioner(tileId.z);
        node.localTransform = positioner.createTransformMatrix(tileId, size);
      }
    });

    // Apply device pixel ratio scaling
    final view = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = view.display.devicePixelRatio;
    canvas.scale(1 / pixelRatio);

    // Render the scene
    _scene.render(OrthographicCamera(pixelRatio), canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  // Default camera configuration for 2D tile rendering
}

/// Context required for scene rendering operations
abstract class SceneRenderingContext {
  /// Creates a tile positioner for the given zoom level
  TilePositioner createTilePositioner(int zoom);

  double get zoom;
}

/// Utility functions for working with tile identities in node names
class TileNodeUtils {
  /// Parses tile identity from a node name format like "z=2,x=1,y=0"
  static BaseTileIdentity? parseFromNodeName(String nodeName) {
    try {
      final parts = nodeName.split(',');
      if (parts.length == 3) {
        final z = int.parse(parts[0].split('=')[1]);
        final x = int.parse(parts[1].split('=')[1]);
        final y = int.parse(parts[2].split('=')[1]);
        return BaseTileIdentity(z, x, y);
      }
    } catch (e) {
      // Invalid node name format
    }
    return null;
  }
}