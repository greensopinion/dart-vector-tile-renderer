import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_generator.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_provider.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';

import '../../vector_tile_renderer.dart';
import 'bucket_unpacker.dart';
import 'orthographic_camera.dart';
import 'position_transform.dart';
import 'text/atlas_creating_text_visitor.dart';
import 'tile_prerenderer.dart';
import 'tile_render_data.dart';

class TileId {
  final int z;
  final int x;
  final int y;

  TileId({required this.z, required this.x, required this.y});


  @override
  String toString() => key();

  String key() => 'z=$z,x=$x,y=$y';
}

class TileUiModel {
  final TileId tileId;
  final Rect position;
  final Tileset tileset;
  final RasterTileset rasterTileset;
  final Uint8List? renderData;

  TileUiModel(
      {required this.tileId,
      required this.position,
      required this.tileset,
      required this.rasterTileset,
      required this.renderData});
}

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TilesRenderer {
  static final Completer<void> _initializer = Completer<void>();
  static Future<void> initialize = _initializer.future;

  final _positionByKey = <String, Rect>{};
  final AtlasProvider _atlasProvider = AtlasProvider();
  final TextureProvider _textureProvider = TextureProvider();
  late final _atlasGenerator = AtlasGenerator(atlasProvider: _atlasProvider, textureProvider: _textureProvider);
  Theme theme;
  Scene? _scene;

  TilesRenderer(this.theme) {
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

  Uint8List Function(Theme theme, double zoom, Tileset tileset, String tileID) getPreRenderer() {
    final atlasProvider = _atlasProvider;
    return (Theme theme, double zoom, Tileset tileset, String tileID) => TilePreRenderer().preRender(theme, zoom, tileset, atlasProvider.forTileID(tileID));
  }

  Future preRenderUi(double zoom, Tileset tileset, String tileID) async {
    final visitor = AtlasCreatingTextVisitor(_atlasGenerator, theme);
    visitor.visitAllFeatures(tileset, zoom);

    await visitor.finish(tileID);
  }

  void update(double zoom, List<TileUiModel> models, Iterable<String> tileIDs) {
    final scene = this.scene;
    final nodesByKey =
        Map.fromEntries(scene.root.children.map((n) => MapEntry(n.name, n)));
    scene.root.removeAll();
    _positionByKey.clear();
    for (final model in models) {
      final key = 'z=${model.tileId.z},x=${model.tileId.x},y=${model.tileId.y}';
      var node = nodesByKey[key];
      if (node == null) {
        node = Node(name: key);
        final renderData = model.renderData;
        if (renderData == null) {
          throw Exception("no render data for tile ${model.tileId}, did you call preRender?");
        }
        BucketUnpacker(_textureProvider).unpackOnto(node, TileRenderData.unpack(renderData));
      }
      _positionByKey[key] = model.position;
      scene.add(node);
    }

    _atlasGenerator.unloadWhereNotFound(tileIDs.toSet());
  }

  void render(ui.Canvas canvas, ui.Size size, double rotation) {
    // Apply device pixel ratio scaling
    final view = ui.PlatformDispatcher.instance.views.first;
    final pixelRatio = view.display.devicePixelRatio;
    canvas.scale(1 / pixelRatio);

    for (final node in scene.root.children) {
      final position = _positionByKey[node.name];
      if (position != null) {
        node.localTransform = tileTransformMatrix(position, size, rotation);
      }
    }
    scene.render(OrthographicCamera(pixelRatio, rotation), canvas,
        viewport: ui.Offset.zero & canvas.getLocalClipBounds().size);
  }

  Scene _createScene() {
    Scene scene = Scene();
    scene.antiAliasingMode = AntiAliasingMode.msaa;
    return scene;
  }

  void dispose() {
  }
}
