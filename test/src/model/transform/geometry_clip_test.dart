import 'dart:math';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';
import 'package:vector_tile_renderer/src/model/transform/geometry_clip.dart';

void main() {
  group('line clip', () {
    test('entirely outside of the clip area', () {
      var clipped = clipLine(
          TileLine([const TilePoint(0, 0), const TilePoint(10, 10)]),
          const ClipArea(11, 11, 10, 10));
      expect(clipped, []);
    });
    test('entirely inside of the clip area', () {
      final line = TileLine([const TilePoint(0, 0), const TilePoint(10, 10)]);
      var clipped = clipLine(line, const ClipArea(-1, -1, 20, 20)).round();
      expect(clipped, [line]);
    });

    group('outside inside', () {
      test('horizontal line', () {
        final line = TileLine([const TilePoint(-2, 4), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(0, 4), const TilePoint(4, 4)])
        ]);
      });
      test('vertical line', () {
        final line = TileLine([const TilePoint(4, -2), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(4, 0), const TilePoint(4, 4)])
        ]);
      });
      test('diagonal line low to high left to right', () {
        final line = TileLine([const TilePoint(-2, -2), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(0, 0), const TilePoint(4, 4)])
        ]);
      });
      test('diagonal line low to high left to right negative y intersection',
          () {
        final line = TileLine([const TilePoint(-1, -3), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(1.14286, 0), const TilePoint(4, 4)])
        ]);
      });

      test('diagonal line high to low left to right', () {
        final line = TileLine([const TilePoint(-2, 12), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(0, 9.33333), const TilePoint(4, 4)])
        ]);
      });

      test(
          'diagonal line high to low left to right positive y intersection negative x',
          () {
        final line = TileLine([const TilePoint(-1, 12), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(0.25, 10), const TilePoint(4, 4)])
        ]);
      });
      test(
          'diagonal line high to low left to right positive y intersection positive x',
          () {
        final line = TileLine([const TilePoint(1, 12), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(1.75, 10), const TilePoint(4, 4)])
        ]);
      });
      test(
          'diagonal line high to low right to left positive y intersection positive x gt inside',
          () {
        final line = TileLine([const TilePoint(7, 12), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(6.25, 10), const TilePoint(4, 4)])
        ]);
      });
      test(
          'diagonal line high to low right to left positive y intersection positive x gt bounds',
          () {
        final line = TileLine([const TilePoint(13, 12), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(10, 9.33333), const TilePoint(4, 4)])
        ]);
      });
      test('diagonal line high to low right to left positive x gt bounds', () {
        final line = TileLine([const TilePoint(13, 8), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(10, 6.66667), const TilePoint(4, 4)])
        ]);
      });
      test('diagonal line low to high right to left positive x gt bounds', () {
        final line = TileLine([const TilePoint(13, 2), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(10, 2.66667), const TilePoint(4, 4)])
        ]);
      });
      test(
          'diagonal line low to high right to left positive x gt bounds y lt bounds',
          () {
        final line = TileLine([const TilePoint(12, -2), const TilePoint(4, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(9.33333, 0), const TilePoint(4, 4)])
        ]);
      });

      test('diagonal line inside outside \\', () {
        final line = TileLine([const TilePoint(5, 5), const TilePoint(4, -1)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const TilePoint(5.0, 5.0), const TilePoint(4.16667, 0.0)])
        ]);
      });

      test('diagonal line failing case', () {
        final line = TileLine(
            [const TilePoint(787.0, 252.0), const TilePoint(601.0, -4.0)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 800, 800)).round();
        expect(clipped, [
          TileLine(
              [const TilePoint(787.0, 252.0), const TilePoint(603.90625, 0.0)])
        ]);
      });
    });

    group('reentry inside outside', () {
      test('in out in', () {
        final line = TileLine([
          const TilePoint(7, 8),
          const TilePoint(12, -3),
          const TilePoint(4, 4)
        ]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const Point(7.0, 8.0), const Point(10.0, 1.4)]),
          TileLine([const Point(8.57143, 0.0), const Point(4.0, 4.0)])
        ]);
      });
      test('in out in same side', () {
        final line = TileLine([
          const TilePoint(7, 8),
          const TilePoint(11, 13),
          const TilePoint(12, 3),
          const TilePoint(4, 4)
        ]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([const Point(7.0, 8.0), const Point(8.6, 10.0)]),
          TileLine([const Point(10.0, 3.25), const Point(4.0, 4.0)])
        ]);
      });
    });

    group('no points inside with intersection', () {
      test('basic crossing line', () {
        final line = TileLine([const TilePoint(-3, 4), const TilePoint(6, -2)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([
            const Point(0.0, 2.0),
            const Point(1.5, 1.0),
            const Point(3.0, 0.0)
          ])
        ]);
      });

      test('vertical crossing line', () {
        final line = TileLine([const TilePoint(4, -1), const TilePoint(4, 11)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([
            const Point(4.0, 0.0),
            const Point(4.0, 5.0),
            const Point(4.0, 10.0)
          ])
        ]);
      });
      test('horizontal crossing line', () {
        final line = TileLine([const TilePoint(-1, 4), const TilePoint(11, 4)]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([
            const Point(0.0, 4.0),
            const Point(5.0, 4.0),
            const Point(10.0, 4.0)
          ])
        ]);
      });

      test('multiple crossing lines', () {
        final line = TileLine([
          const TilePoint(-3, 4),
          const TilePoint(6, -2),
          const TilePoint(14, 0),
          const TilePoint(1, 12)
        ]);
        var clipped = clipLine(line, const ClipArea(0, 0, 10, 10)).round();
        expect(clipped, [
          TileLine([
            const Point(0.0, 2.0),
            const Point(1.5, 1.0),
            const Point(3.0, 0.0)
          ]),
          TileLine([
            const Point(10.0, 3.69231),
            const Point(7.5, 6.0),
            const Point(3.16667, 10.0)
          ])
        ]);
      });
    });
  });

  group('polygon clip', () {
    group('simple polygons', () {
      test('intersecting', () {
        final polygon = TilePolygon([
          TileLine([
            const TilePoint(-3, 4),
            const TilePoint(6, -2),
            const TilePoint(14, 0),
            const TilePoint(1, 12)
          ])
        ]);
        var clipped =
            clipPolygon(polygon, const ClipArea(0, 0, 10, 10))?.round();
        expect(
            clipped,
            TilePolygon([
              TileLine([
                const TilePoint(0.0, 10.0),
                const TilePoint(0.0, 10.0),
                const TilePoint(0.0, 2.0),
                const TilePoint(3.0, 0.0),
                const TilePoint(10.0, 0.0),
                const TilePoint(10.0, 3.69231),
                const TilePoint(3.16667, 10.0)
              ])
            ]));
      });

      test('fully contains clip', () {
        final polygon = TilePolygon([
          TileLine([
            const TilePoint(-1, -1),
            const TilePoint(11, -1),
            const TilePoint(11, 11),
            const TilePoint(-1, 11)
          ])
        ]);
        var clipped =
            clipPolygon(polygon, const ClipArea(0, 0, 10, 10))?.round();
        expect(
            clipped,
            TilePolygon([
              TileLine([
                const TilePoint(0.0, 10.0),
                const TilePoint(0.0, 0.0),
                const TilePoint(10.0, 0.0),
                const TilePoint(10.0, 10.0)
              ])
            ]));
      });

      test('overlap', () {
        final polygon = TilePolygon([
          TileLine([
            const TilePoint(3, -1),
            const TilePoint(3, 3),
            const TilePoint(5, 3),
            const TilePoint(5, -1)
          ])
        ]);
        var clipped =
            clipPolygon(polygon, const ClipArea(0, 0, 10, 10))?.round();
        expect(
            clipped,
            TilePolygon([
              TileLine([
                const Point(3.0, 0.0),
                const Point(3.0, 3.0),
                const Point(5.0, 3.0),
                const Point(5.0, 0.0)
              ])
            ]));
      });

      test('two overlaps', () {
        final polygon = TilePolygon([
          TileLine([
            const TilePoint(3, -1),
            const TilePoint(3, 3),
            const TilePoint(5, 3),
            const TilePoint(5, -1),
            const TilePoint(6, -1),
            const TilePoint(6, 3),
            const TilePoint(7, 3),
            const TilePoint(7, -1),
          ])
        ]);
        var clipped =
            clipPolygon(polygon, const ClipArea(0, 0, 10, 10))?.round();
        expect(
            clipped,
            TilePolygon([
              TileLine([
                const Point(3.0, 0.0),
                const Point(3.0, 3.0),
                const Point(5.0, 3.0),
                const Point(5.0, 0.0),
                const Point(6.0, 0.0),
                const Point(6.0, 3.0),
                const Point(7.0, 3.0),
                const Point(7.0, 0.0)
              ])
            ]));
      });
      test('ends outside at a corner', () {
        final polygon = TilePolygon([
          TileLine([
            const TilePoint(-2, 8),
            const TilePoint(2, 8),
            const TilePoint(2, 12),
            const TilePoint(-2, 12)
          ])
        ]);
        var clipped =
            clipPolygon(polygon, const ClipArea(0, 0, 10, 10))?.round();
        expect(
            clipped,
            TilePolygon([
              TileLine([
                const TilePoint(0.0, 10.0),
                const TilePoint(0.0, 8.0),
                const TilePoint(2.0, 8.0),
                const TilePoint(2.0, 10.0)
              ])
            ]));
      });
    });
  });
}

extension _TilePolygonExtension on TilePolygon {
  TilePolygon round() => TilePolygon(rings.map((l) => l.round()).toList());
}

extension _TileLineListExtension on List<TileLine> {
  List<TileLine> round() => map((l) => l.round()).toList();
}

extension _TileLineExtension on TileLine {
  TileLine round() => TileLine(points.map((e) => e.round()).toList());
}

extension _TilePointExtension on TilePoint {
  TilePoint round() =>
      TilePoint(x.roundToDecimalPlaces(5), y.roundToDecimalPlaces(5));
}

extension _DoubleExtension on double {
  double roundToDecimalPlaces(int places) {
    final mod = pow(10.0, places);
    return (this * mod).roundToDouble() / mod;
  }
}
