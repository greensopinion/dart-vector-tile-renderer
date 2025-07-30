import 'dart:isolate';
import 'dart:typed_data';

import 'package:vector_tile_renderer/src/gpu/concurrent/shared/keys.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/worker/line_geometry_builder.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/worker/polygon_geometry_builder.dart';

import '../../../model/geometry_model.dart';

void main(List<String> args, SendPort sendPort) {

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((data) {
    if (data is Map<String, dynamic>) {
      final GeometryType type = GeometryType.values[data[GeometryKeys.type]];
      final String id = data[GeometryKeys.jobId];
      ByteData vertices, indices;

      switch(type) {
        case GeometryType.line:
          final List<List<TilePoint>> points = data[LineKeys.lines];
          final LineEnd ends = LineEnd.values[data[LineKeys.ends]];
          final LineJoin joins = LineJoin.values[data[LineKeys.joins]];

          (vertices, indices) = LineGeometryBuilder().build(points, ends, joins);
        case GeometryType.poly:
          final List<TilePolygon> polygons = data[PolyKeys.polygons];

          (vertices, indices) = PolygonGeometryBuilder().build(polygons);
      }
      sendPort.send({
        GeometryKeys.vertices: vertices,
        GeometryKeys.indices: indices,
        GeometryKeys.type: type.index,
        GeometryKeys.jobId: id
      });
    }
  });
}