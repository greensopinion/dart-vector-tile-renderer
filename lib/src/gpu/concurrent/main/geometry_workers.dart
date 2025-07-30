
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/main/transferable_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/main/util/concurrent_hashmap.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/shared/keys.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';

import '../worker/main.dart' as worker;
import '../../../model/geometry_model.dart';

void _workerEntryPoint(SendPort sendPort) {
  worker.main([], sendPort);
}

class GeometryWorkers extends ChangeNotifier {

  GeometryWorkers() {
    _runSetup();
  }

  late final SendPort _sendPort;
  final Completer<void> _setup = Completer();



  final ConcurrentHashMap<String, Completer<Geometry>> _inFlightRequests = ConcurrentHashMap();

  Future<void> _runSetup() async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);

    receivePort.listen((data) {
      if (data is SendPort && !_setup.isCompleted) {
        _sendPort = data;
        _setup.complete();
      } else if (data is Map<String, dynamic>) {
        final String jobId = data[GeometryKeys.jobId];
        _inFlightRequests.get(jobId).then((completer) {
          completer?.complete(TransferableGeometry(data).unpack());
          _inFlightRequests.remove(jobId);

          _inFlightRequests.length.then((length) {
            if (length == 0) {
              notifyListeners();
            }
          });
        });
      }
    });
  }

  Future<LineGeometry> submitLines(List<List<TilePoint>> lines, LineJoin lineJoins, LineEnd lineEnds) {
    return _setup.future.then((_){
      final String jobId = UniqueKey().toString();

      _sendPort.send({
        GeometryKeys.jobId: jobId,
        GeometryKeys.type: GeometryType.line.index,
        LineKeys.lines: lines,
        LineKeys.joins: lineJoins.index,
        LineKeys.ends: lineEnds.index
      });

      final Completer<LineGeometry> completer = Completer();
      _inFlightRequests.put(jobId, completer);
      return completer.future;
    });
  }
}

