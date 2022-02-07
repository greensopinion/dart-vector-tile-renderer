import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/src/features/label_space.dart';
import 'package:vector_tile_renderer/src/tileset.dart';

import '../context.dart';
import '../logger.dart';
import '../model/tile_model.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import 'line_renderer.dart';
import 'polygon_renderer.dart';
import 'symbol_line_renderer.dart';
import 'symbol_point_renderer.dart';

class FeatureRendererContext implements Context {
  FeatureRendererContext(this._context, this.pixelsPerTileUnit);

  final Context _context;
  final double pixelsPerTileUnit;

  @override
  LabelSpace get labelSpace => _context.labelSpace;

  @override
  set labelSpace(LabelSpace _labelSpace) => _context.labelSpace = _labelSpace;

  @override
  Canvas get canvas => _context.canvas;

  @override
  FeatureDispatcher get featureRenderer => _context.featureRenderer;

  @override
  Logger get logger => _context.logger;

  @override
  Tile? tile(String sourceId) => _context.tile(sourceId);

  @override
  Rect get tileClip => _context.tileClip;

  @override
  Rect get tileSpace => _context.tileSpace;

  @override
  Tileset get tileset => _context.tileset;

  @override
  double get zoom => _context.zoom;

  @override
  double get zoomScaleFactor => _context.zoomScaleFactor;

  double widthFromPixelToTile(double value) {
    return value / pixelsPerTileUnit;
  }

  Offset pointFromTileToPixels(Offset point) {
    return point * pixelsPerTileUnit;
  }

  Size sizeFromTileToPixels(Size point) {
    return point * pixelsPerTileUnit;
  }

  Rect rectFromTileToPixels(Rect rect) {
    return pointFromTileToPixels(rect.topLeft) &
        sizeFromTileToPixels(rect.size);
  }

  bool isPathWithinTileClip(Path path) {
    return tileClip.overlaps(rectFromTileToPixels(path.getBounds()));
  }

  void drawInTileSpace(void Function() fn) {
    canvas.save();
    canvas.scale(pixelsPerTileUnit);
    fn();
    canvas.restore();
  }

  void drawInPixelSpace(void Function() fn) {
    canvas.save();
    canvas.scale(1 / pixelsPerTileUnit);
    fn();
    canvas.restore();
  }
}

abstract class FeatureRenderer {
  void render(
    FeatureRendererContext context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  );
}

class FeatureDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<TileFeatureType, FeatureRenderer> typeToRenderer;
  final Map<TileFeatureType, FeatureRenderer> symbolTypeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger),
        symbolTypeToRenderer = createSymbolDispatchMapping(logger);

  void render(
    FeatureRendererContext context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    final rendererMapping = layerType == ThemeLayerType.symbol
        ? symbolTypeToRenderer
        : typeToRenderer;
    final delegate = rendererMapping[feature.type];
    if (delegate == null) {
      logger.warn(() =>
          'layer type $layerType feature ${feature.type} is not implemented');
    } else {
      delegate.render(context, layerType, style, layer, feature);
    }
  }

  static Map<TileFeatureType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {
      TileFeatureType.polygon: PolygonRenderer(logger),
      TileFeatureType.linestring: LineRenderer(logger),
    };
  }

  static Map<TileFeatureType, FeatureRenderer> createSymbolDispatchMapping(
      Logger logger) {
    return {
      TileFeatureType.point: SymbolPointRenderer(logger),
      TileFeatureType.linestring: SymbolLineRenderer(logger)
    };
  }
}
