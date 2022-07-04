import 'package:fixnum/fixnum.dart';
import 'package:vector_tile/vector_tile.dart';

import '../extensions.dart';
import '../logger.dart';
import '../themes/expression/expression.dart';
import '../themes/theme.dart';
import '../themes/theme_layers.dart';
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

  Tile create(VectorTile tile) {
    return Tile(
        layers: tile.layers
            // .where((layer) => layerNames.contains(layer.name))
            .map(_vectorLayerToTileLayer)
            .whereType<TileLayer>()
            .toList(growable: false));
  }

  TileLayer? _vectorLayerToTileLayer(VectorTileLayer vectorLayer) {
    return TileLayer(
        name: vectorLayer.name,
        extent: vectorLayer.extent,
        features: vectorLayer.features
            .map(_vectorFeatureToTileFeature)
            .whereType<TileFeature>()
            .toList(growable: false));
  }

  TileFeature? _vectorFeatureToTileFeature(VectorTileFeature vectorFeature) {
    final type = vectorFeature.type;
    if (type == null || type == VectorTileGeomType.UNKNOWN) {
      return null;
    }
    if (type == VectorTileGeomType.POINT) {
      return TileFeature(
        type: TileFeatureType.point,
        properties: _decodeProperties(vectorFeature),
        geometry: vectorFeature.geometryList!,
      );
    } else if (type == VectorTileGeomType.LINESTRING) {
      return TileFeature(
        type: TileFeatureType.linestring,
        properties: _decodeProperties(vectorFeature),
        geometry: vectorFeature.geometryList!,
      );
    } else if (type == VectorTileGeomType.POLYGON) {
      return TileFeature(
        type: TileFeatureType.polygon,
        properties: _decodeProperties(vectorFeature),
        geometry: vectorFeature.geometryList!,
      );
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
    names.addProperties(this.style.fillPaint);
    names.addProperties(this.style.linePaint);
    names.addProperties(this.style.outlinePaint);
    names.addProperties(this.style.textPaint);
    names.addProperties(this.style.textLayout?.text);
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
