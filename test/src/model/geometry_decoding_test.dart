import 'dart:math';

import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/model/geometry_decoding.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';
import 'package:vector_tile_renderer/src/model/geometry_model_ui.dart';

const moveTo = 0x1;
const lineTo = 0x2;
const closePath = 0x7;

int command(int command, int length) => length << 3 | command;

int zigZag(int n) => ((n << 1) ^ (n >> 31)).toSigned(32);

void main() {
  final uiGeometry = UiGeometry();

  group('point', () {
    test('single point', () {
      final points = decodePoints([
        command(moveTo, 1),
        zigZag(0),
        zigZag(1),
      ]).toList();

      expect(points, [const TilePoint(0, 1)]);
    });

    test('multiple points', () {
      final points = decodePoints([
        command(moveTo, 2),
        zigZag(0),
        zigZag(1),
        zigZag(2),
        zigZag(3),
      ]).toList();

      expect(points, [const TilePoint(0, 1), const TilePoint(2, 3)]);
    });
  });

  group('line string', () {
    test('single line string', () {
      final lines = decodeLineStrings([
        command(moveTo, 1),
        zigZag(0),
        zigZag(1),
        command(lineTo, 1),
        zigZag(2),
        zigZag(3),
      ]).toList();

      expect(lines, hasLength(1));
      final metric = uiGeometry.createLine(lines[0]).computeMetrics().first;
      expect(metric.getTangentForOffset(0)!.position, const Offset(0, 1));
      expect(metric.getTangentForOffset(metric.length)!.position,
          const Offset(2, 4));
    });

    test('multiple line string', () {
      final lines = decodeLineStrings([
        command(moveTo, 1),
        zigZag(0),
        zigZag(1),
        command(lineTo, 1),
        zigZag(2),
        zigZag(3),
        command(moveTo, 1),
        zigZag(0),
        zigZag(1),
        command(lineTo, 1),
        zigZag(2),
        zigZag(3),
      ]).toList();

      expect(lines, hasLength(2));

      final line0Metric =
          uiGeometry.createLine(lines[0]).computeMetrics().first;
      expect(
        line0Metric.getTangentForOffset(0)!.position,
        const Offset(0, 1),
      );
      expect(
        line0Metric.getTangentForOffset(line0Metric.length)!.position,
        const Offset(2, 4),
      );

      final line1Metric =
          uiGeometry.createLine(lines[1]).computeMetrics().first;
      expect(
        line1Metric.getTangentForOffset(0)!.position,
        const Offset(2, 5),
      );
      expect(
        line1Metric.getTangentForOffset(line0Metric.length)!.position,
        const Offset(4, 8),
      );
    });
  });

  group('polygon', () {
    test('with single ring', () {
      final polygons = decodePolygons([
        // Outer rings must be clockwise.
        // 0
        // | \
        // 2 - 1
        command(moveTo, 1),
        zigZag(0), // 0,0
        zigZag(0),
        command(lineTo, 2),
        zigZag(1), // 1,1
        zigZag(1),
        zigZag(-1), // 0,1
        zigZag(0),
        command(closePath, 1),
      ]).toList();

      expect(polygons, hasLength(1));

      final polygonMetrics =
          uiGeometry.createPolygon(polygons[0]).computeMetrics().toList();
      expect(polygonMetrics, hasLength(1));

      final ringMetric = polygonMetrics[0];
      expect(ringMetric.getTangentForOffset(0)!.position, const Offset(0, 0));
      expect(
        ringMetric.getTangentForOffset(sqrt(2))!.position,
        const Offset(1, 1),
      );
      expect(
        ringMetric.getTangentForOffset(sqrt(2) + 1)!.position,
        const Offset(0, 1),
      );
    });

    test('with multiple rings', () {
      final polygons = decodePolygons([
        // Outer rings must be clockwise.
        // 0
        // | \
        // 2 - 1
        command(moveTo, 1),
        zigZag(0), // 0,0
        zigZag(0),
        command(lineTo, 2),
        zigZag(1), // 1,1
        zigZag(1),
        zigZag(-1), // 0,1
        zigZag(0),
        command(closePath, 1),
        // Inner rings must be counter clockwise.
        // 0
        // | \
        // 1 - 2
        command(moveTo, 1),
        zigZag(0), // 0,0
        zigZag(-1),
        command(lineTo, 2),
        zigZag(0), // 0,1
        zigZag(1),
        zigZag(1), // 1,1
        zigZag(0),
        command(closePath, 1),
      ]).toList();

      final polygonMetrics =
          uiGeometry.createPolygon(polygons[0]).computeMetrics().toList();
      expect(polygonMetrics, hasLength(2));

      final innerRingMetric = polygonMetrics[1];
      expect(
          innerRingMetric.getTangentForOffset(0)!.position, const Offset(0, 0));
      expect(
        innerRingMetric.getTangentForOffset(1)!.position,
        const Offset(0, 1),
      );
      expect(
        innerRingMetric.getTangentForOffset(2)!.position,
        const Offset(1, 1),
      );
    });

    test('multiple polygons', () {
      final polygons = decodePolygons([
        // Outer rings must be clockwise.
        // 0
        // | \
        // 2 - 1
        command(moveTo, 1),
        zigZag(0), // 0,0
        zigZag(0),
        command(lineTo, 2),
        zigZag(1), // 1,1
        zigZag(1),
        zigZag(-1), // 0,1
        zigZag(0),
        command(closePath, 1),
        // Each outer ring starts a new polygon.
        // 0
        // | \
        // 2 - 1
        command(moveTo, 1),
        zigZag(0), // 0,0
        zigZag(-1),
        command(lineTo, 2),
        zigZag(1), // 1,1
        zigZag(1),
        zigZag(-1), // 0,1
        zigZag(0),
        command(closePath, 1),
      ]).toList();

      expect(polygons, hasLength(2));
    });
  });
}
