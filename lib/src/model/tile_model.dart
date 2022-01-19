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

abstract class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;

  TileFeature(this.type, this.properties);

  List<List<Point>> get lines => [];
  List<Point> get points => [];
  List<List<List<Point>>> get polygons => [];
}

enum TileFeatureType { point, linestring, polygon }

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
