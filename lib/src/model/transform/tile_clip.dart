import '../../constants.dart';
import '../geometry_model.dart';
import '../tile_data_model.dart';
import 'geometry_clip.dart';

class TileClip {
  /// clip in pixel space
  final ClipArea bounds;

  TileClip({required this.bounds});

  TileData clip(TileData original) => TileData(
      layers:
          original.layers.map((e) => _clipLayer(e)).toList(growable: false));

  TileDataLayer _clipLayer(TileDataLayer original) {
    final pixelsPerTileUnit = 1 / original.extent * tileSize;
    final tileClip = ClipArea(
        bounds.left / pixelsPerTileUnit,
        bounds.top / pixelsPerTileUnit,
        bounds.width / pixelsPerTileUnit,
        bounds.height / pixelsPerTileUnit);
    return TileDataLayer(
        name: original.name,
        extent: original.extent,
        features: original.features
            .map((e) => _clipFeature(e, tileClip))
            .whereType<TileDataFeature>()
            .toList(growable: false));
  }

  TileDataFeature? _clipFeature(TileDataFeature original, ClipArea clip) {
    if (original.hasPoints) {
      final points = original.points
          .where((p) => clip.containsPoint(p))
          .toList(growable: false);
      return points.isEmpty
          ? null
          : TileDataFeature(
              type: original.type,
              properties: original.properties,
              geometry: null,
              points: points);
    } else if (original.hasLines) {
      final lines = original.lines
          .expand((l) => clipLine(l, clip))
          .whereType<TileLine>()
          .toList(growable: false);
      return lines.isEmpty
          ? null
          : TileDataFeature(
              type: original.type,
              properties: original.properties,
              geometry: null,
              lines: lines);
    } else {
      final polygons = original.polygons
          .map((p) => clipPolygon(p, clip))
          .whereType<TilePolygon>()
          .toList(growable: false);
      return polygons.isEmpty
          ? null
          : TileDataFeature(
              type: original.type,
              properties: original.properties,
              geometry: null,
              polygons: polygons);
    }
  }
}
