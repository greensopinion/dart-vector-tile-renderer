import 'tile_model.dart';

class MultiLineTileFeature extends TileFeature {
  final List<List<Point>> coordinates;

  MultiLineTileFeature(
      {required TileFeatureType type,
      required Map<String, dynamic> properties,
      required this.coordinates})
      : super(type, properties);

  @override
  List<List<Point>> get lines => coordinates;
  @override
  List<List<List<Point>>> get polygons => [coordinates];
}

class MultiMultiLineTileFeature extends TileFeature {
  final List<List<List<Point>>> coordinates;

  MultiMultiLineTileFeature(
      {required TileFeatureType type,
      required Map<String, dynamic> properties,
      required this.coordinates})
      : super(type, properties);
  @override
  List<List<List<Point>>> get polygons => coordinates;
}

class LineTileFeature extends TileFeature {
  final List<Point> coordinates;

  LineTileFeature(
      {required TileFeatureType type,
      required Map<String, dynamic> properties,
      required this.coordinates})
      : super(type, properties);

  @override
  List<List<Point>> get lines => [coordinates];
  @override
  List<Point> get points => coordinates;
}

class PointTileFeature extends TileFeature {
  final Point coordinate;

  PointTileFeature(
      {required TileFeatureType type,
      required Map<String, dynamic> properties,
      required this.coordinate})
      : super(type, properties);
  @override
  List<Point> get points => [coordinate];
}
