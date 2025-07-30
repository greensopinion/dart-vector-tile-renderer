import 'dart:ui';

import 'geometry_model.dart';
import 'geometry_model_ui.dart';
import 'package:dart_earcut/dart_earcut.dart';

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

class TriangulatedPolygon {
  final List<double> normalizedVertices;
  final List<int> indices;

  TriangulatedPolygon({
    required this.normalizedVertices,
    required this.indices,
  });

  factory TriangulatedPolygon.fromTilePolygon(TilePolygon polygon) {
    final flat = <double>[];
    final holeIndices = <int>[];

    for (int i = 0; i < polygon.rings.length; i++) {
      final ring = polygon.rings[i];

      if (i > 0) {
        holeIndices.add(flat.length ~/ 2);
      }

      for (final point in ring.points) {
        flat.add(point.x.toDouble());
        flat.add(point.y.toDouble());
      }
    }

    final indices = Earcut.triangulateRaw(flat, holeIndices: holeIndices);

    final normalized = <double>[];
    for (var i = 0; i < flat.length; i += 2) {
      final x = flat[i], y = flat[i + 1];
      normalized.addAll([
        x / 2048.0 - 1,
        1 - y / 2048.0,
        0.0,
      ]);
    }

    return TriangulatedPolygon(
      normalizedVertices: normalized,
      indices: indices,
    );
  }

  void combine(TriangulatedPolygon other) {
    int offset = (normalizedVertices.length / 3).truncate();
    indices.addAll(other.indices.map((it) => (it + offset)));
    normalizedVertices.addAll(other.normalizedVertices);
  }
}

class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;
  final List<TilePoint>? _modelPoints;
  final List<TileLine>? _modelLines;
  final List<TilePolygon>? _modelPolygons;
  List<Offset>? _points;
  List<BoundedPath>? _paths;
  BoundedPath? _compoundPath;
  TriangulatedPolygon? _earcutPolygons;

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

  List<Offset> get points {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }
    var points = _points;
    if (points == null) {
      final modelPoints = _modelPoints;
      if (modelPoints == null) {
        points = [];
      } else {
        final uiGeometry = UiGeometry();
        points = modelPoints
            .map((e) => uiGeometry.createPoint(e))
            .toList(growable: false);
      }
      _points = points;
    }
    return points;
  }

  bool get hasPaths =>
      type == TileFeatureType.linestring || type == TileFeatureType.polygon;

  bool get hasPoints => type == TileFeatureType.point;

  bool get hasPolygons => type == TileFeatureType.polygon;

  BoundedPath get compoundPath {
    var compoundPath = _compoundPath;
    if (compoundPath == null) {
      final paths = this.paths;
      if (paths.length == 1) {
        compoundPath = paths.first;
      } else {
        final linesPath = Path();
        for (final line in paths) {
          linesPath.addPath(line.path, Offset.zero);
        }
        compoundPath = BoundedPath(linesPath);
      }
      _compoundPath = compoundPath;
    }
    return compoundPath;
  }

  List<BoundedPath> get paths {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }
    var paths = _paths;
    if (paths == null) {
      final modelLines = _modelLines;
      final modelPolygons = _modelPolygons;
      if (modelPolygons != null) {
        assert(type == TileFeatureType.polygon);
        final uiGeometry = UiGeometry();
        paths = modelPolygons
            .map((e) => BoundedPath(uiGeometry.createPolygon(e)))
            .toList(growable: false);
      } else if (modelLines != null) {
        assert(type == TileFeatureType.linestring);
        final uiGeometry = UiGeometry();
        paths = modelLines
            .map((e) => BoundedPath(uiGeometry.createLine(e)))
            .toList(growable: false);
      } else {
        paths = [];
      }
      _paths = paths;
    }
    return paths;
  }

  TriangulatedPolygon get earcutPolygons {
    var earcutPolygons = _earcutPolygons;
    if (earcutPolygons == null) {
      final polygons = modelPolygons;
      final triangulated = polygons.map((polygon) => TriangulatedPolygon.fromTilePolygon(polygon)).toList();

      List<double> vertices = [];
      List<int> indices = [];

      for (var it in triangulated) {
        indices.addAll(it.indices.map((i) => i + (vertices.length / 3).truncate()));
        vertices.addAll(it.normalizedVertices);
      }

      earcutPolygons = TriangulatedPolygon(normalizedVertices: vertices, indices: indices);

      _earcutPolygons = earcutPolygons;
    }
    return earcutPolygons;
  }
}

enum TileFeatureType { point, linestring, polygon, background, none }
