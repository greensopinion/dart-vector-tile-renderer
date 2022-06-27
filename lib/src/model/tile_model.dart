import 'dart:collection';
import 'dart:ui';

import 'path_utils.dart';
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
  final List<int>? _geometry;
  List<Offset>? _points;
  List<Path>? _paths;
  HashMap<List<double>, List<Path>> _dashedPaths = HashMap();

  TileFeature({
    required this.type,
    required this.properties,
    required List<int> geometry,
  }) : _geometry = geometry;

  List<Offset> get points {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }

    final geometry = _geometry;
    if (geometry != null && _points == null) {
      _points = decodePoints(geometry).toList(growable: false);
    }

    return _points ?? [];
  }

  List<Path> getPaths({List<double> dashLengths = const []}) {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }

    final geometry = _geometry;
    if (geometry != null) {
      if (_paths == null) {
        // ignore: missing_enum_constant_in_switch
        switch (type) {
          case TileFeatureType.linestring:
            _paths = decodeLineStrings(geometry).toList(growable: false);
            break;
          case TileFeatureType.polygon:
            _paths = decodePolygons(geometry).toList(growable: false);
            break;
        }
      }
    }

    if (dashLengths.length >= 2) {
      if (_dashedPaths.containsKey(dashLengths)) {
        return _dashedPaths[dashLengths]!;
      } else {
        final path = _paths
                ?.map((e) => e.dashPath(RingNumberProvider(dashLengths)))
                .toList() ??
            [];
        _dashedPaths[dashLengths] = path;
        return path;
      }
    } else {
      return _paths ?? [];
    }
  }
}

enum TileFeatureType { point, linestring, polygon, background }
