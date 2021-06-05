import 'package:vector_tile/util/geometry.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import '../logger.dart';

class FeatureGeometry {
  final Logger logger;

  FeatureGeometry(this.logger);

  List<List<List<double>>>? decodeLines(VectorTileFeature feature) {
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry.type == GeometryType.LineString) {
        final linestring = geometry as GeometryLineString;
        return [linestring.coordinates];
      } else if (geometry.type == GeometryType.MultiLineString) {
        final linestring = geometry as GeometryMultiLineString;
        return linestring.coordinates;
      } else {
        logger.warn(() =>
            'linestring geometryType=${geometry.type} is not implemented');
        return null;
      }
    }
    return null;
  }

  List<List<double>>? decodePoints(VectorTileFeature feature) {
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry.type == GeometryType.Point) {
        final point = geometry as GeometryPoint;
        return [point.coordinates];
      } else if (geometry.type == GeometryType.MultiPoint) {
        final multiPoint = geometry as GeometryMultiPoint;
        return multiPoint.coordinates;
      } else {
        logger.warn(
            () => 'point geometryType=${geometry.type} is not implemented');
        return null;
      }
    }
    return null;
  }
}
