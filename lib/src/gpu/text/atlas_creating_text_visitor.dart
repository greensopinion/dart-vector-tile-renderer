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

  Future<void> finish(String tileID) async {
    for (final entry in fontToCharCodes.entries) {
      final font = entry.key;
      final charCodes = entry.value;

      if (charCodes.isEmpty) {
        continue;
      }

      final filtered = charCodes.toList()..sort();

      if (filtered.first < 256) {
        await atlasGenerator.loadAtlas(str: _defaultChars, fontFamily: font, tileID: "");
        if (filtered.last >= 256) {
          final chop = filtered.indexWhere((it) => it >= 256);
          filtered.removeRange(0, chop);
        } else {
          continue;
        }
      }

      for (var i = 0; i < filtered.length; i += 256) {
        final end = (i + 256 < filtered.length) ? i + 256 : filtered.length;
        final charChunk = filtered.sublist(i, end);
        await atlasGenerator.loadAtlas(
          str: String.fromCharCodes(charChunk),
          fontFamily: font,
          tileID: tileID
        );
      }
    }

    fontToCharCodes.clear();
  }

  static final String _defaultChars = String.fromCharCodes(List.generate(256, (i) => i));


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
