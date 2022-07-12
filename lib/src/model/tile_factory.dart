import 'package:fixnum/fixnum.dart';
import 'package:vector_tile/vector_tile.dart';

import '../extensions.dart';
import '../logger.dart';
import '../themes/expression/expression.dart';
import '../themes/theme.dart';
import '../themes/theme_layers.dart';
import 'tile_data_model.dart';
import 'tile_model.dart';

class TileFactory {
  final Logger logger;
  final Theme theme;
  late final Set<String> propertyNames;
  late final Set<String> layerNames;
  TileFactory(this.theme, this.logger) {
    final layers =
        theme.layers.whereType<DefaultLayer>().toList(growable: false);
    propertyNames = layers.map((e) => e.propertyNames()).flatSet();
    layerNames =
        layers.map((e) => e.selector.layerSelector.layerNames()).flatSet();
  }

  TileData createTileData(VectorTile tile) {
    return TileData(
        layers: tile.layers
            .map(_vectorLayerToTileDataLayer)
            .whereType<TileDataLayer>()
            .toList(growable: false));
  }

  Tile create(VectorTile tile) {
    return createTileData(tile).toTile();
  }

  TileDataLayer? _vectorLayerToTileDataLayer(VectorTileLayer vectorLayer) {
    return TileDataLayer(
        name: vectorLayer.name,
        extent: vectorLayer.extent,
        features: vectorLayer.features
            .map(_vectorFeatureToTileDataFeature)
            .whereType<TileDataFeature>()
            .toList(growable: false));
  }

  TileDataFeature? _vectorFeatureToTileDataFeature(
      VectorTileFeature vectorFeature) {
    final type = vectorFeature.type;
    if (type == null || type == VectorTileGeomType.UNKNOWN) {
      return null;
    }
    if (type == VectorTileGeomType.POINT) {
      return TileDataFeature(
          type: TileFeatureType.point,
          properties: _decodeProperties(vectorFeature),
          geometry: vectorFeature.geometryList!);
    } else if (type == VectorTileGeomType.LINESTRING) {
      return TileDataFeature(
          type: TileFeatureType.linestring,
          properties: _decodeProperties(vectorFeature),
          geometry: vectorFeature.geometryList!);
    } else if (type == VectorTileGeomType.POLYGON) {
      return TileDataFeature(
          type: TileFeatureType.polygon,
          properties: _decodeProperties(vectorFeature),
          geometry: vectorFeature.geometryList!);
    }
    return null;
  }

  Map<String, dynamic> _decodeProperties(VectorTileFeature feature) {
    final properties = feature.decodeProperties();
    // properties.removeWhere((key, value) => !propertyNames.contains(key));
    // feature.properties = null;
    return properties.map((key, value) => MapEntry(key, _convertValue(value)));
  }

  _convertValue(VectorTileValue value) {
    final v = value.value;
    if (v is Int64) {
      return v.toInt();
    }
    return v;
  }
}

extension _DefaultLayerExtension on DefaultLayer {
  Set<String> propertyNames() {
    final names = <String>{};
    names.addAll(selector.layerSelector.propertyNames());
    names.addProperties(style.fillPaint);
    names.addProperties(style.linePaint);
    names.addProperties(style.outlinePaint);
    names.addProperties(style.textPaint);
    names.addProperties(style.textLayout?.text);
    return names.whereType<String>().toSet();
  }
}

extension _StringSet on Set<String> {
  void addProperties(Expression? expression) {
    if (expression != null) {
      addAll(expression.properties());
    }
  }
}
