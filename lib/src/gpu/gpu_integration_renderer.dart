import 'dart:ui';

import 'package:vector_tile_renderer/src/context.dart';
import 'package:vector_tile_renderer/src/themes/theme.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class GpuIntegrationRenderer {
  final Theme theme;

  GpuIntegrationRenderer({required this.theme});

  void render(Context context, Canvas canvas, Size size) {
    final effectiveTheme = theme.atZoom(context.zoom);

    final groups = _groupLayersByEngine(context, effectiveTheme.layers);
    for (final group in groups) {
      if (group.engine == _Engine.gpu) {
        context.logger.log(() => 'rendering gpu layers');
        final theme = Theme(
            id: effectiveTheme.id,
            version: effectiveTheme.version,
            layers: group.layers);
        final gpuRenderer = TileRenderer(
            theme: theme, zoom: context.zoom, logger: context.logger);
        gpuRenderer.tileset = context.tileSource.tileset;
        gpuRenderer.render(canvas, size);
      } else {
        for (final layer in group.layers) {
          context.logger.log(() => 'rendering theme layer ${layer.id}');
          layer.render(context);
        }
      }
    }
  }
}

List<_LayerGroup> _groupLayersByEngine(
    Context context, List<ThemeLayer> layers) {
  final groups = <_LayerGroup>[];
  for (final layer in layers) {
    final engine =
        context.optimizations.gpuRendering ? _engineOf(layer) : _Engine.canvas;
    final _LayerGroup group;
    if (groups.isEmpty || groups.last.engine != engine) {
      group = _LayerGroup(engine, [layer]);
      groups.add(group);
    } else {
      group = groups.last;
    }
    group.layers.add(layer);
  }
  return groups;
}

_Engine _engineOf(ThemeLayer layer) {
  if (layer.type == ThemeLayerType.line ||
      layer.type == ThemeLayerType.background) {
    return _Engine.gpu;
  }
  return _Engine.canvas;
}

class _LayerGroup {
  final _Engine engine;
  final List<ThemeLayer> layers;

  _LayerGroup(this.engine, this.layers);
}

enum _Engine {
  gpu,
  canvas,
}
