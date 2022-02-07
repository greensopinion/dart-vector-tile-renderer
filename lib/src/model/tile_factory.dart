import 'package:fixnum/fixnum.dart';
import 'package:vector_tile/vector_tile.dart';

import '../extensions.dart';
import '../logger.dart';
import '../themes/paint_factory.dart';
import '../themes/theme.dart';
import '../themes/theme_layers.dart';
import 'tile_features.dart';
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
      final coordinates = vectorFeature.decodePoint();
      if (coordinates.length == 1) {
        return PointTileFeature(
            type: TileFeatureType.point,
            properties: _decodeProperties(vectorFeature),
            coordinate: coordinates[0].toPoint());
      } else {
        return LineTileFeature(
            type: TileFeatureType.point,
            properties: _decodeProperties(vectorFeature),
            coordinates:
                coordinates.map((e) => e.toPoint()).toList(growable: false));
      }
    } else if (type == VectorTileGeomType.LINESTRING) {
      final lines = vectorFeature.decodeLineString();
      if (lines.length == 1) {
        return LineTileFeature(
            type: TileFeatureType.linestring,
            properties: _decodeProperties(vectorFeature),
            coordinates:
                lines[0].map((e) => e.toPoint()).toList(growable: false));
      } else {
        return MultiLineTileFeature(
            type: TileFeatureType.linestring,
            properties: _decodeProperties(vectorFeature),
            coordinates: lines
                .map((line) => line
                    .map((point) => point.toPoint())
                    .toList(growable: false))
                .toList(growable: false));
      }
    } else if (type == VectorTileGeomType.POLYGON) {
      final polygons = vectorFeature.decodePolygon();
      if (polygons.length == 1) {
        return MultiLineTileFeature(
            type: TileFeatureType.polygon,
            properties: _decodeProperties(vectorFeature),
            coordinates: polygons[0]
                .map((line) => line
                    .map((point) => point.toPoint())
                    .toList(growable: false))
                .toList(growable: false));
      } else {
        return MultiMultiLineTileFeature(
            type: TileFeatureType.polygon,
            properties: _decodeProperties(vectorFeature),
            coordinates: polygons
                .map((lines) => lines
                    .map((line) => line
                        .map((point) => point.toPoint())
                        .toList(growable: false))
                    .toList(growable: false))
                .toList(growable: false));
      }
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

extension _ListPointExtension on List<int> {
  Point toPoint() {
    return Point(this[0], this[1]);
  }
}

extension _DefaultLayerExtension on DefaultLayer {
  Set<String> propertyNames() {
    final names = <String>{};
    names.addAll(selector.layerSelector.propertyNames());
    names.addPaintStyleProperties(this.style.fillPaint);
    names.addPaintStyleProperties(this.style.linePaint);
    names.addPaintStyleProperties(this.style.outlinePaint);
    names.addPaintStyleProperties(this.style.textPaint);
    names.addAllOptional(this.style.textLayout?.text.properties());
    return names.whereType<String>().toSet();
  }
}

extension _StringSet on Set<String> {
  void addAllOptional(Set<String>? values) {
    if (values != null) {
      addAll(values);
    }
  }

  void addPaintStyleProperties(PaintStyle? style) {
    if (style != null) {
      addAllOptional(style.opacity.properties());
      addAllOptional(style.strokeWidth.properties());
    }
  }
}
