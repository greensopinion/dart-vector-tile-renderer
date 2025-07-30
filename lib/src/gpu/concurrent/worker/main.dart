import 'dart:isolate';

import 'package:vector_tile_renderer/src/gpu/concurrent/shared/keys.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/worker/line_geometry_builder.dart';

import '../../../model/geometry_model.dart';

void main(List<String> args, SendPort sendPort) {

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((data) {
    if (data is Map<String, dynamic>) {
      final GeometryType type = GeometryType.values[data[GeometryKeys.type]];

      switch(type) {
        case GeometryType.line:
          final List<List<TilePoint>> points = data[LineKeys.lines];
          final LineEnd ends = LineEnd.values[data[LineKeys.ends]];
          final LineJoin joins = LineJoin.values[data[LineKeys.joins]];
          final String id = data[GeometryKeys.jobId];

          final (vertices, indices) = LineGeometryBuilder().build(points, ends, joins);
          sendPort.send({
            GeometryKeys.vertices: vertices,
            GeometryKeys.indices: indices,
            GeometryKeys.type: type.index,
            GeometryKeys.jobId: id
          });
        case GeometryType.poly:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }
  });
}