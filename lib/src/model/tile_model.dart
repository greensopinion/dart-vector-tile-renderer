import 'dart:ui';

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
  final List<Path> paths;
  final List<Offset> points;

  TileFeature({
    required this.type,
    required this.properties,
    List<Path>? paths,
    List<Offset>? points,
  })  : paths = paths ?? const [],
        points = points ?? const [];
}

enum TileFeatureType { point, linestring, polygon }

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
