
import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/uniform_spline.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/uniform_spline_base.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/linear_spline.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

import 'integral_approximation.dart';

class ParametricUniformSpline {
  final UniformSplineInterpolationBase splineX;
  final UniformSplineInterpolationBase splineY;

  /// Creates a parametric spline with custom interpolation strategy
  ParametricUniformSpline(
    List<TilePoint> points,
    UniformSplineInterpolationBase Function(List<double>) createSpline,
  )   : assert(points.length >= 2),
        splineX = createSpline(points.map((p) => p.x).toList()),
        splineY = createSpline(points.map((p) => p.y).toList());

  /// Creates a parametric spline with cubic (smooth) interpolation
  factory ParametricUniformSpline.cubic(List<TilePoint> points) {
    return ParametricUniformSpline(
      points,
      (ys) => UniformSplineInterpolation(ys),
    );
  }

  /// Creates a parametric spline with linear interpolation
  factory ParametricUniformSpline.linear(List<TilePoint> points) {
    return ParametricUniformSpline(
      points,
      (ys) => LinearUniformSplineInterpolation(ys),
    );
  }

  TilePoint valueAt(double t) =>
      TilePoint(splineX.interpolate(t), splineY.interpolate(t));

  TilePoint derivativeAt(double t) =>
      TilePoint(splineX.derivative(t), splineY.derivative(t));

  double rotationAt(double t) =>
      atan2(splineY.derivative(t), splineX.derivative(t));



  double indexFromSignedDistance(double t0, double distance) {
    double sign = distance.sign;
    if (sign != 1 && sign != -1) return t0;

    final int numSegments = splineX.numSegments;
    double targetDistance = distance.abs();

    int startIndex = t0.floor();
    int endIndex = sign > 0 ? numSegments - 1 : 0;

    double accumulatedDistance = 0.0;
    double t = t0;
    int currentIndex = startIndex;

    while (_shouldContinueIteration(sign, currentIndex, endIndex)) {
      double nextT = _computeNextBoundary(t, currentIndex, sign, t0, targetDistance);
      double segmentDistance = signedDistance(t, nextT).abs();

      if (accumulatedDistance + segmentDistance >= targetDistance) {
        return _findExactParameterByDistance(t0, t, nextT, targetDistance);
      }

      accumulatedDistance += segmentDistance;
      t = nextT;
      currentIndex += sign.toInt();
    }

    return _getEndpoint(sign, numSegments);
  }

  bool _shouldContinueIteration(double sign, int currentIndex, int endIndex) {
    return (sign > 0 && currentIndex <= endIndex) ||
           (sign < 0 && currentIndex >= endIndex);
  }

  double _computeNextBoundary(double t, int currentIndex, double sign,
                               double t0, double targetDistance) {
    double nextT = sign > 0 ? currentIndex + 1.0 : currentIndex.toDouble();

    bool exceedsTarget = (sign > 0 && nextT > t0 + targetDistance) ||
                         (sign < 0 && nextT < t0 - targetDistance);

    if (exceedsTarget) {
      nextT = t + (sign > 0 ? 1 : -1);
    }

    return nextT;
  }

  double _findExactParameterByDistance(double t0, double low, double high,
                                       double targetDistance) {
    for (int i = 0; i < 20; i++) {
      double mid = (low + high) / 2;
      double midDistance = signedDistance(t0, mid).abs();

      if (midDistance < targetDistance) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low + high) / 2;
  }

  double _getEndpoint(double sign, int numSegments) {
    return sign > 0 ? numSegments.toDouble() : 0.0;
  }


  double signedDistance(double t0, double t1) {
    if (t0 == t1) return 0.0;

    final sign = (t1 - t0).sign;
    final start = min(t0, t1);
    final stop = max(t0, t1);

    double totalDistance = 0.0;
    double currentStart = start;

    // Walk through each integer segment between start and stop
    while (currentStart < stop) {
      double nextBoundary = currentStart.ceilToDouble();
      if (nextBoundary == currentStart && nextBoundary < stop) {
        nextBoundary = currentStart + 1.0;
      }
      final currentEnd = min(nextBoundary, stop);
      totalDistance += _signedDistanceClamped(currentStart, currentEnd);
      currentStart = currentEnd;
    }

    return totalDistance * sign;
  }

  double _signedDistanceClamped(double t0, double t1) {
    double start = min(t0, t1);
    double stop = max(t0, t1);

    final sign = (t1 - t0).sign;
    if (sign != 1 && sign != -1) return 0.0;

    final index = start.toInt();
    final indexDouble = index.toDouble();

    if (index >= splineX.numSegments || index < 0) return 0.0;

    start = start.clamp(indexDouble, indexDouble + 1);
    stop = stop.clamp(indexDouble, indexDouble + 1);

    final dxDt = splineX.derivativePolynomial(index);
    final dyDt = splineY.derivativePolynomial(index);

    final speedSquared = Polynomial.sum(dxDt.squared(), dyDt.squared());

    return IntegralApproximation.trapezoidalSqrtFunc(speedSquared, start, stop) * sign;
  }
}

