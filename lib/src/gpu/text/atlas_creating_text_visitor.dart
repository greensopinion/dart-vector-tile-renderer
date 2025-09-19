import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_generator.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';

class AtlasCreatingTextVisitor extends LayerVisitor {
  final AtlasGenerator atlasGenerator;
  final Theme theme;

  final fontToCharCodes = <String, Set<int>>{};

  AtlasCreatingTextVisitor(this.atlasGenerator, this.theme);

  void visitAllFeatures(Tileset tileset, double zoom) {
    final context = VisitorContext(
      logger: const Logger.noop(),
      tileSource: TileSource(
          tileset: tileset, rasterTileset: const RasterTileset(tiles: {})),
      zoom: zoom,
    );

    for (var layer in theme.layers) {
      layer.accept(context, this);
    }
  }

  Future<void> finish() async {
    for (final entry in fontToCharCodes.entries) {
      final font = entry.key;
      final charCodes = entry.value;

      final filtered = charCodes
          .where((code) => !atlasGenerator.isCharLoaded(font, code))
          .toList();

      for (var i = 0; i < filtered.length; i += 256) {
        final end = (i + 256 < filtered.length) ? i + 256 : filtered.length;
        final charChunk = filtered.sublist(i, end);
        await atlasGenerator.loadAtlas(
          str: String.fromCharCodes(charChunk..sort()),
          fontFamily: font,
        );
      }
    }

    fontToCharCodes.clear();
  }


  @override
  void visitFeatures(
      VisitorContext context,
      ThemeLayerType layerType,
      Style style,
      Iterable<LayerFeature> features) {
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null) {
      return;
    }
    if (layerType == ThemeLayerType.symbol) {
      for (var feature in features) {
        final evaluationContext = EvaluationContext(
            () => feature.feature.properties,
            TileFeatureType.none,
            context.logger,
            zoom: context.zoom,
            zoomScaleFactor: 1.0,
            hasImage: (_) => false);

        final text = symbolLayout.text?.text.evaluate(evaluationContext);
        if (text == null || text.isEmpty) {
          continue;
        }
        final fontFamily = symbolLayout.text?.fontFamily ?? 'Roboto Regular';
        fontToCharCodes.putIfAbsent(fontFamily, () => <int>{}).addAll(text.codeUnits);
      }
    }
  }
}
