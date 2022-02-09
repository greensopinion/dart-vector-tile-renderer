import 'dart:ui';

import 'geometry_decoding.dart';

class Tile {
  final List<TileLayer> layers;

  Tile({required this.layers});
}

class TileLayer {
  final String name;
  final int extent;
  final List<TileFeature> features;

  TileLayer({required this.name, required this.extent, required this.features});
}

class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;
  List<int>? _geometry;
  late List<Offset> _points;
  late List<Path> _paths;

  TileFeature({
    required this.type,
    required this.properties,
    required List<int> geometry,
  }) : _geometry = geometry;

  List<Offset> get points {
    if (type != TileFeatureType.point) {
      throw Exception('Feature does not have points');
    }

    final geometry = _geometry;
    if (geometry != null) {
      _points = decodePoints(geometry).toList(growable: false);
      _geometry = null;
    }

    return _points;
  }

  List<Path> get paths {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }

    final geometry = _geometry;
    if (geometry != null) {
      // ignore: missing_enum_constant_in_switch
      switch (type) {
        case TileFeatureType.linestring:
          _paths = decodeLineStrings(geometry).toList(growable: false);
          break;
        case TileFeatureType.polygon:
          _paths = decodePolygons(geometry).toList(growable: false);
          break;
      }
      _geometry = null;
    }

    return _paths;
  }
}

enum TileFeatureType { point, linestring, polygon }
