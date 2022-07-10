import '../../constants.dart';
import '../geometry_model.dart';
import '../tile_data_model.dart';

class TileTranslate {
  final TilePoint _offset;

  TileTranslate(this._offset);

  TileData translate(TileData tile) => TileData(
      layers: tile.layers.map(_translateLayer).toList(growable: false));

  TileDataLayer _translateLayer(TileDataLayer layer) {
    final pixelsPerTileUnit = 1 / layer.extent * tileSize;
    final translation =
        TilePoint(_offset.x / pixelsPerTileUnit, _offset.y / pixelsPerTileUnit);
    return TileDataLayer(
        name: layer.name,
        extent: layer.extent,
        features: layer.features
            .map((f) => _translateFeature(f, translation))
            .toList(growable: false));
  }

  TileDataFeature _translateFeature(
          TileDataFeature feature, TilePoint translation) =>
      TileDataFeature(
          type: feature.type,
          properties: feature.properties,
          geometry: null,
          points: feature.hasPoints
              ? feature.points.map((p) => _translatePoint(p, translation))
              : null,
          lines: feature.hasLines
              ? feature.lines.map((l) => _translateLine(l, translation))
              : null,
          polygons: feature.hasPolygons
              ? feature.polygons.map((p) => _translatePolygon(p, translation))
              : null);

  TilePoint _translatePoint(TilePoint point, TilePoint translation) =>
      TilePoint(point.x + translation.x, point.y + translation.y);

  TileLine _translateLine(TileLine line, TilePoint translation) =>
      TileLine(line.points
          .map((p) => _translatePoint(p, translation))
          .toList(growable: false));

  TilePolygon _translatePolygon(TilePolygon polygon, TilePoint translation) =>
      TilePolygon(polygon.rings
          .map((l) => _translateLine(l, translation))
          .toList(growable: false));
}
