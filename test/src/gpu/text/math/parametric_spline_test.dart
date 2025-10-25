import 'dart:math';
import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/parametric_spline.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

void main() {
  group('ParametricUniformSpline', () {
    group('construction', () {
      test('creates spline from points', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);
        expect(spline, isNotNull);
      });

      test('requires at least two points', () {
        expect(
          () => ParametricUniformSpline([TilePoint(0.0, 0.0)]),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('valueAt', () {
      test('passes through all control points', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 2.0),
          TilePoint(2.0, 1.0),
          TilePoint(3.0, 3.0),
        ];
        final spline = ParametricUniformSpline(points);

        for (int i = 0; i < points.length; i++) {
          final value = spline.valueAt(i.toDouble());
          expect(value.x, closeTo(points[i].x, 0.0001));
          expect(value.y, closeTo(points[i].y, 0.0001));
        }
      });

      test('interpolates between points', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(2.0, 2.0),
        ];
        final spline = ParametricUniformSpline(points);

        final midpoint = spline.valueAt(0.5);
        // Should be between the two points
        expect(midpoint.x, greaterThan(0.0));
        expect(midpoint.x, lessThan(2.0));
        expect(midpoint.y, greaterThan(0.0));
        expect(midpoint.y, lessThan(2.0));
      });

      test('handles horizontal line', () {
        final points = [
          TilePoint(0.0, 5.0),
          TilePoint(1.0, 5.0),
          TilePoint(2.0, 5.0),
        ];
        final spline = ParametricUniformSpline(points);

        expect(spline.valueAt(0.5).y, closeTo(5.0, 0.0001));
        expect(spline.valueAt(1.5).y, closeTo(5.0, 0.0001));
      });

      test('handles vertical line', () {
        final points = [
          TilePoint(5.0, 0.0),
          TilePoint(5.0, 1.0),
          TilePoint(5.0, 2.0),
        ];
        final spline = ParametricUniformSpline(points);

        expect(spline.valueAt(0.5).x, closeTo(5.0, 0.0001));
        expect(spline.valueAt(1.5).x, closeTo(5.0, 0.0001));
      });
    });

    group('derivativeAt', () {
      test('returns zero derivative for stationary point', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(0.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final deriv = spline.derivativeAt(0.5);
        expect(deriv.x, closeTo(0.0, 0.0001));
        expect(deriv.y, closeTo(0.0, 0.0001));
      });

      test('has positive x-derivative for rightward motion', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(10.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final deriv = spline.derivativeAt(0.5);
        expect(deriv.x, greaterThan(0.0));
      });

      test('has positive y-derivative for upward motion', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(0.0, 10.0),
        ];
        final spline = ParametricUniformSpline(points);

        final deriv = spline.derivativeAt(0.5);
        expect(deriv.y, greaterThan(0.0));
      });
    });

    group('rotationAt', () {
      test('returns 0 for rightward horizontal line', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final rotation = spline.rotationAt(0.5);
        expect(rotation, closeTo(0.0, 0.01));
      });

      test('returns pi/2 for upward vertical line', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(0.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        final rotation = spline.rotationAt(0.5);
        expect(rotation, closeTo(pi / 2, 0.01));
      });

      test('returns pi for leftward horizontal line', () {
        final points = [
          TilePoint(1.0, 0.0),
          TilePoint(0.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final rotation = spline.rotationAt(0.5);
        expect(rotation.abs(), closeTo(pi, 0.01));
      });

      test('returns -pi/2 for downward vertical line', () {
        final points = [
          TilePoint(0.0, 1.0),
          TilePoint(0.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final rotation = spline.rotationAt(0.5);
        expect(rotation, closeTo(-pi / 2, 0.01));
      });

      test('returns pi/4 for diagonal line at 45 degrees', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        final rotation = spline.rotationAt(0.5);
        expect(rotation, closeTo(pi / 4, 0.01));
      });
    });

    group('signedDistance', () {
      test('returns zero for same parameter', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        expect(spline.signedDistance(0.5, 0.5), equals(0.0));
      });

      test('returns positive distance forward along curve', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final distance = spline.signedDistance(0.0, 1.0);
        expect(distance, greaterThan(0.0));
        expect(distance, closeTo(1.0, 0.01)); // Should be close to 1 unit
      });

      test('returns negative distance backward along curve', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final distance = spline.signedDistance(1.0, 0.0);
        expect(distance, lessThan(0.0));
        expect(distance, closeTo(-1.0, 0.01));
      });

      test('is antisymmetric', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final forward = spline.signedDistance(0.5, 1.5);
        final backward = spline.signedDistance(1.5, 0.5);

        expect(backward, closeTo(-forward, 0.0001));
      });

      test('handles diagonal line distance correctly', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(3.0, 4.0), // 3-4-5 triangle
        ];
        final spline = ParametricUniformSpline(points);

        final distance = spline.signedDistance(0.0, 1.0);
        // Euclidean distance is 5, so this should be close
        expect(distance, closeTo(5.0, 0.1));
      });

      test('accumulates distance across multiple segments', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final distance = spline.signedDistance(0.0, 2.0);
        expect(distance, closeTo(2.0, 0.01));
      });
    });

    group('indexFromSignedDistance', () {
      test('returns same index for zero distance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        expect(spline.indexFromSignedDistance(0.5, 0.0), equals(0.5));
      });

      test('moves forward for positive distance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.0, 0.5);
        expect(result, greaterThan(0.0));
        expect(result, lessThan(2.0));
      });

      test('moves backward for negative distance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(1.0, -0.5);
        expect(result, lessThan(1.0));
        expect(result, greaterThan(0.0));
      });

      test('clamps to start when exceeding backward distance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.5, -10.0);
        expect(result, equals(0.0));
      });

      test('clamps to end when exceeding forward distance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.5, 10.0);
        expect(result, equals(1.0));
      });

      test('approximately inverts signedDistance', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        final t0 = 0.5;
        final t1 = 1.5;
        final distance = spline.signedDistance(t0, t1);
        final tResult = spline.indexFromSignedDistance(t0, distance);

        expect(tResult, closeTo(t1, 0.01));
      });

      test('works for fractional starting position', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.25, 0.5);
        expect(result, greaterThan(0.25));
        expect(result, lessThan(2.0));
      });

      test('handles curved path correctly', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
          TilePoint(2.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.0, 1.0);
        expect(result, greaterThan(0.0));
        expect(result, lessThan(2.0));
      });

      test('handles multiple segments traversal', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 0.0),
          TilePoint(2.0, 0.0),
          TilePoint(3.0, 0.0),
        ];
        final spline = ParametricUniformSpline(points);

        final result = spline.indexFromSignedDistance(0.0, 2.5);
        expect(result, greaterThan(2.0));
        expect(result, lessThan(3.0));
      });
    });

    group('edge cases', () {
      test('handles very short spline', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(0.001, 0.001),
        ];
        final spline = ParametricUniformSpline(points);

        final value = spline.valueAt(0.5);
        expect(value.x.isFinite, isTrue);
        expect(value.y.isFinite, isTrue);
      });

      test('handles spline with coincident points', () {
        final points = [
          TilePoint(0.0, 0.0),
          TilePoint(0.0, 0.0),
          TilePoint(1.0, 1.0),
        ];
        final spline = ParametricUniformSpline(points);

        final value = spline.valueAt(1.0);
        expect(value.x, closeTo(0.0, 0.0001));
        expect(value.y, closeTo(0.0, 0.0001));
      });

      test('handles large coordinates', () {
        final points = [
          TilePoint(1000.0, 2000.0),
          TilePoint(1100.0, 2100.0),
        ];
        final spline = ParametricUniformSpline(points);

        final value = spline.valueAt(0.5);
        expect(value.x, greaterThan(1000.0));
        expect(value.x, lessThan(1100.0));
        expect(value.y, greaterThan(2000.0));
        expect(value.y, lessThan(2100.0));
      });

      test('handles negative coordinates', () {
        final points = [
          TilePoint(-10.0, -20.0),
          TilePoint(-5.0, -10.0),
        ];
        final spline = ParametricUniformSpline(points);

        final value = spline.valueAt(0.5);
        expect(value.x, lessThan(-5.0));
        expect(value.x, greaterThan(-10.0));
        expect(value.y, lessThan(-10.0));
        expect(value.y, greaterThan(-20.0));
      });
    });
  });
}
