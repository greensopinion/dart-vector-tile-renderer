import 'dart:ui';

import 'geometry_model.dart';

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
  List<TilePoint>? _modelPoints;
  List<TileLine>? _modelLines;
  List<TilePolygon>? _modelPolygons;
  late List<Offset> _points;
  late List<Path> _paths;

  TileFeature(
      {required this.type,
      required this.properties,
      required List<TilePoint>? points,
      required List<TileLine>? lines,
      required List<TilePolygon>? polygons})
      : _modelPoints = points,
        _modelLines = lines,
        _modelPolygons = polygons;

  List<Offset> get points {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }
    final modelPoints = _modelPoints;
    if (modelPoints != null) {
      final uiGeometry = UiGeometry();
      _points = modelPoints
          .map((e) => uiGeometry.createPoint(e))
          .toList(growable: false);
      _modelPoints = null;
    }
    return _points;
  }

  bool get hasPaths =>
      type == TileFeatureType.linestring || type == TileFeatureType.polygon;

  bool get hasPoints => type == TileFeatureType.point;

  List<Path> get paths {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }
    final modelLines = _modelLines;
    if (modelLines != null) {
      assert(type == TileFeatureType.linestring);
      final uiGeometry = UiGeometry();
      _paths = modelLines
          .map((e) => uiGeometry.createLine(e))
          .toList(growable: false);
      _modelLines = null;
    }
    final modelPolygons = _modelPolygons;
    if (modelPolygons != null) {
      assert(type == TileFeatureType.polygon);
      final uiGeometry = UiGeometry();
      _paths = modelPolygons
          .map((e) => uiGeometry.createPolygon(e))
          .toList(growable: false);
      _modelPolygons = null;
    }
    return _paths;
  }
}

enum TileFeatureType { point, linestring, polygon, background }
