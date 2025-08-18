import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../features/feature_renderer.dart';
import '../optimizations.dart';

/// Experimental: renders tiles using flutter_gpu and Canvas, depending on the
/// capabilities of this library.
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TileRendererComposite {
  final Theme theme;
  final bool gpuRenderingEnabled;
  final double zoom;
  final Logger logger;
  late final List<_LayerGroup> _groups;
  final TileSource tile;
  final FeatureDispatcher featureRenderer;
  final TextPainterProvider painterProvider;
  TileRendererComposite(
      {required this.theme,
      required this.tile,
      required this.gpuRenderingEnabled,
      required this.zoom,
      this.painterProvider = const DefaultTextPainterProvider(),
      this.logger = const Logger.noop()})
      : featureRenderer = FeatureDispatcher(logger) {
    final effectiveTheme = theme.atZoom(zoom);
    _groups = _groupLayersByEngine(effectiveTheme.layers);
  }

  void render(Canvas canvas, Size size,
      {Rect? clip, required double zoomScaleFactor, required double rotation}) {
    final tileSpace =
        Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble());
    canvas.save();
    canvas.clipRect(tileSpace);
    final tileClip = clip ?? tileSpace;
    final optimizations = Optimizations(
        skipInBoundsChecks: clip == null ||
            (tileClip.width - tileSpace.width).abs() < (tileSpace.width / 2));
    final context = Context(
        logger: logger,
        canvas: canvas,
        featureRenderer: featureRenderer,
        tileSource: tile,
        zoomScaleFactor: zoomScaleFactor,
        zoom: zoom,
        rotation: rotation,
        tileSpace: tileSpace,
        tileClip: tileClip,
        optimizations: optimizations,
        textPainterProvider: painterProvider);

    for (final group in _groups) {
      group.render(context, canvas, size);
    }
    canvas.restore();
  }

  _Engine _engineOf(ThemeLayer layer) {
    if (gpuRenderingEnabled) {
      if (layer.type == ThemeLayerType.line ||
          layer.type == ThemeLayerType.background ||
          layer.type == ThemeLayerType.fill ||
          layer.type == ThemeLayerType.raster) {
        return _Engine.gpu;
      }
    }
    return _Engine.canvas;
  }

  List<_LayerGroup> _groupLayersByEngine(List<ThemeLayer> layers) {
    final groups = <_LayerGroup>[];
    for (final layer in layers) {
      final engine = _engineOf(layer);
      final _LayerGroup group;
      if (groups.isEmpty || groups.last.engine != engine) {
        // switch (engine) {
        //   case _Engine.gpu:
        //     group = _GpuLayerGroup(theme, engine);
        //     break;
        //   case _Engine.canvas:
        //     group = _CanvasLayerGroup(theme, engine);
        //     break;
        // }
        group = _CanvasLayerGroup(theme, engine);
        groups.add(group);
      } else {
        group = groups.last;
      }
      group.layers.add(layer);
    }
    return groups;
  }
}

abstract class _LayerGroup {
  final Theme theme;
  final _Engine engine;
  final List<ThemeLayer> layers = [];

  Theme get effectiveTheme =>
      Theme(id: theme.id, version: theme.version, layers: layers);

  _LayerGroup(this.theme, this.engine);

  void render(Context context, Canvas canvas, Size size);
}

class _GpuLayerGroup extends _LayerGroup {
  TilesRenderer? renderer;

  _GpuLayerGroup(super.theme, super.engine);

  @override
  void render(Context context, Canvas canvas, Size size) {
    var renderer = this.renderer;
    if (renderer == null) {
      // renderer = TilesRenderer(
      //     theme: effectiveTheme, zoom: context.zoom,
      //     geometryWorkers: GeometryWorkers(),
      //     logger: context.logger);
      // renderer.tileSource = context.tileSource;
      this.renderer = renderer;
    }
    // renderer.render(canvas, size);
  }
}

class _CanvasLayerGroup extends _LayerGroup {
  _CanvasLayerGroup(super.theme, super.engine);

  @override
  void render(Context context, Canvas canvas, Size size) {
    for (final layer in layers) {
      layer.render(context);
    }
  }
}

enum _Engine {
  gpu,
  canvas,
}
