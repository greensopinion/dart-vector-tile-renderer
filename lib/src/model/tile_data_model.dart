import 'package:vector_tile_renderer/src/model/geometry_decoding.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

import 'tile_model.dart';

class TileData {
  final List<TileDataLayer> layers;

  TileData({required this.layers});

  Tile toTile() =>
      Tile(layers: layers.map((e) => e.toTileLayer()).toList(growable: false));
}

class TileDataLayer {
  final String name;
  final int extent;
  final List<TileDataFeature> features;

  TileDataLayer(
      {required this.name, required this.extent, required this.features});

  TileLayer toTileLayer() => TileLayer(
      name: name,
      extent: extent,
      features: features.map((e) => e.toTileFeature()).toList(growable: false));
}

class TileDataFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;
  final List<int> geometry;
  Iterable<TilePoint>? _points;
  Iterable<TileLine>? _lines;
  Iterable<TilePolygon>? _polygons;

  TileDataFeature(
      {required this.type,
      required this.properties,
      required this.geometry,
      Iterable<TilePoint>? points,
      Iterable<TileLine>? lines,
      Iterable<TilePolygon>? polygons})
      : _points = points,
        _lines = lines,
        _polygons = polygons;

  bool get hasLines => type == TileFeatureType.linestring;
  bool get hasPolygons => type == TileFeatureType.polygon;
  bool get hasPoints => type == TileFeatureType.point;

  Iterable<TilePoint> get points {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }
    var points = _points;
    if (points == null) {
      points = decodePoints(geometry);
      _points = points;
    }
    return points;
  }

  Iterable<TileLine> get lines {
    if (type != TileFeatureType.linestring) {
      throw StateError('Feature does not have lines');
    }
    var lines = _lines;
    if (lines == null) {
      lines = decodeLineStrings(geometry);
      _lines = lines;
    }
    return lines;
  }

  Iterable<TilePolygon> get polygons {
    if (type != TileFeatureType.polygon) {
      throw StateError('Feature does not have polygons');
    }
    var polygons = _polygons;
    if (polygons == null) {
      polygons = decodePolygons(geometry);
      _polygons = polygons;
    }
    return polygons;
  }

  TileFeature toTileFeature() {
    final tilePoints = hasPoints ? points.toList(growable: false) : null;
    final tileLines = hasLines ? lines.toList(growable: false) : null;
    final tilePolygons = hasPolygons ? polygons.toList(growable: false) : null;
    return TileFeature(
        type: type,
        properties: properties,
        points: tilePoints,
        lines: tileLines,
        polygons: tilePolygons);
  }
}
