import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/context.dart';
import 'package:vector_tile_renderer/src/features/feature_renderer.dart';
import 'package:vector_tile_renderer/src/features/tile_space_mapper.dart';
import 'package:vector_tile_renderer/src/gpu/background/background_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/optimizations.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';
import '../../../vector_tile_renderer.dart';

class SceneSymbolBuilder {
  final Scene scene;
  final VisitorContext context;

  final FeatureDispatcher dispatcher = FeatureDispatcher(const Logger.noop());

  SceneSymbolBuilder(this.scene, this.context);

  Future<void> addSymbols(Style style, Iterable<LayerFeature> features) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final context = Context(logger: const Logger.noop(),
        canvas: canvas,
        featureRenderer: dispatcher,
        tileSource: TileSource(tileset: this.context.tileset),
        zoomScaleFactor: 1.0,
        zoom: this.context.zoom,
        rotation: 0.0,
        tileSpace: Rect.fromCenter(center: const Offset(2048, 2048), width: 4096, height: 4096),
        tileClip: Rect.largest,
        optimizations: Optimizations(skipInBoundsChecks: true),
        textPainterProvider: const DefaultTextPainterProvider()
    );

    context.tileSpaceMapper = TileSpaceMapper(canvas, Rect.largest, 512, 4096);

    for (final feature in features) {
      context.featureRenderer.render(
        context,
        ThemeLayerType.symbol,
        style,
        feature.layer,
        feature.feature,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(4096, 4096);

    final material = UnlitMaterial();

    material.baseColorTexture = await gpuTextureFromImage(image);

    scene.addMesh(Mesh(BackgroundGeometry(), material));
  }
}