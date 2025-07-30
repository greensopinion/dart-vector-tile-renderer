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

class BoundedPath {
  final Path path;
  Rect? _bounds;
  List<PathMetric>? _pathMetrics;

  BoundedPath(this.path);

  Rect get bounds {
    var bounds = _bounds;
    if (bounds == null) {
      bounds = path.getBounds();
      _bounds = bounds;
    }
    return bounds;
  }

  List<PathMetric> get pathMetrics {
    var pathMetrics = _pathMetrics;
    if (pathMetrics == null) {
      pathMetrics = path.computeMetrics().toList(growable: false);
      _pathMetrics = pathMetrics;
    }
    return pathMetrics;
  }
}

class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;
  final List<TilePoint>? _modelPoints;
  final List<TileLine>? _modelLines;
  final List<TilePolygon>? _modelPolygons;

  TileFeature(
      {required this.type,
      required this.properties,
      required List<TilePoint>? points,
      required List<TileLine>? lines,
      required List<TilePolygon>? polygons})
      : _modelPoints = points,
        _modelLines = lines,
        _modelPolygons = polygons;

  List<TilePolygon> get modelPolygons => _modelPolygons ?? [];
  List<TileLine> get modelLines => _modelLines ?? [];
  List<TilePoint> get modelPoints => _modelPoints ?? [];

  bool get hasPaths =>
      type == TileFeatureType.linestring || type == TileFeatureType.polygon;

  bool get hasPoints => type == TileFeatureType.point;

  bool get hasPolygons => type == TileFeatureType.polygon;

  /// included so the project compiles without deleting old rendering code
  get paths => null;
  get compoundPath => null;
  get points => null;
}

enum TileFeatureType { point, linestring, polygon, background, none }
