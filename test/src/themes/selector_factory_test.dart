import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/selector_factory.dart';
import 'package:vector_tile_renderer/src/extensions.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../test_logger.dart';
import '../test_tile.dart';

void main() {
  test('matches features with a selector', () async {
    final selector = SelectorFactory(testLogger).create(_minorRoadThemeLayer);
    final tile = await readTestTile();
    final transportationLayer =
        tile.layers.where((layer) => layer.name == 'transportation').first;
    expect(
        selector.select(tile.layers).toList(), contains(transportationLayer));
    final selectedFeatures =
        selector.features(transportationLayer.features).toList();
    expect(selectedFeatures, isNotEmpty);
    expect(selectedFeatures.length, 206);
  });
}

final _minorRoadThemeLayer = {
  "id": "road_minor",
  "type": "line",
  "source": "openmaptiles",
  "source-layer": "transportation",
  "filter": [
    "all",
    ["==", "\$type", "LineString"],
    ["!in", "brunnel", "bridge", "tunnel"],
    ["in", "class", "minor"]
  ],
  "layout": {"line-cap": "round", "line-join": "round"},
  "paint": {
    "line-color": "#fff",
    "line-width": {
      "base": 1.2,
      "stops": [
        [13.5, 0],
        [14, 2.5],
        [20, 18]
      ]
    }
  }
};

String? _stringProperty(VectorTileFeature feature, String name) => feature
    .decodeProperties()
    .map((e) => e[name])
    .whereType<VectorTileValue>()
    .firstOrNull()
    ?.stringValue;
