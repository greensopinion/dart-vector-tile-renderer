import 'package:vector_tile/util/geometry.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import '../logger.dart';

class FeatureGeometry {
  final Logger logger;

  FeatureGeometry(this.logger);

  List<List<List<double>>>? decodeLines(VectorTileFeature feature) {
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry is GeometryLineString) {
        return [geometry.coordinates];
      } else if (geometry is GeometryMultiLineString) {
        return geometry.coordinates;
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
      if (geometry is GeometryPoint) {
        return [geometry.coordinates];
      } else if (geometry is GeometryMultiPoint) {
        return geometry.coordinates;
      } else {
        logger.warn(
            () => 'point geometryType=${geometry.type} is not implemented');
        return null;
      }
    }
    return null;
  }

  List<List<List<List<double>>>>? decodePolygons(VectorTileFeature feature) {
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry is GeometryPolygon) {
        return [geometry.coordinates];
      } else if (geometry is GeometryMultiPolygon) {
        return geometry.coordinates;
      } else {
        logger.warn(
            () => 'polygon geometryType=${geometry.type} is not implemented');
      }
    }
  }
}
