import 'dart:ui';

import 'geometry_model.dart';
import 'geometry_model_ui.dart';
import 'lazy_value.dart';

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

  final _points = LazyValue<List<Offset>>();
  final _paths = LazyValue<List<BoundedPath>>();
  final _compoundPath = LazyValue<BoundedPath>();

  List<Offset> get points => _points.get(_computePoints);
  List<BoundedPath> get paths => _paths.get(_computePaths);
  BoundedPath get compoundPath => _compoundPath.get(_computeCompoundPath);

  List<Offset> _computePoints() {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }
    final modelPoints = _modelPoints;
    if (modelPoints != null) {
      final uiGeometry = UiGeometry();
      return modelPoints
          .map((e) => uiGeometry.createPoint(e))
          .toList(growable: false);
    }
    return [];
  }

  List<BoundedPath> _computePaths() {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }
    final modelLines = _modelLines;
    if (modelLines != null) {
      assert(type == TileFeatureType.linestring);
      final uiGeometry = UiGeometry();
      return modelLines
          .map((e) => BoundedPath(uiGeometry.createLine(e)))
          .toList(growable: false);
    }
    final modelPolygons = _modelPolygons;
    if (modelPolygons != null) {
      assert(type == TileFeatureType.polygon);
      final uiGeometry = UiGeometry();
      return modelPolygons
          .map((e) => BoundedPath(uiGeometry.createPolygon(e)))
          .toList(growable: false);
    }
    return [];
  }

  BoundedPath _computeCompoundPath() {
    final paths = this.paths;
    if (paths.length == 1) {
      return paths.first;
    } else {
      final linesPath = Path();
      for (final line in paths) {
        linesPath.addPath(line.path, Offset.zero);
      }
      return BoundedPath(linesPath);
    }
  }
}

enum TileFeatureType { point, linestring, polygon, background, none }
