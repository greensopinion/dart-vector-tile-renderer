import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../expression.dart';

abstract class InterpolationExpression<T> extends Expression<T> {
  final Expression<double> input;
  final List<FunctionStop<T>> stops;

  InterpolationExpression(this.input, this.stops);

  double getInterpolationFactor(
    double input,
    double lowerValue,
    double upperValue,
  );

  exponentialInterpolation(
      double input, double base, double lowerValue, double upperValue) {
    final difference = upperValue - lowerValue;
    final progress = input - lowerValue;
    if (difference == 0) {
      return 0;
    } else if (base == 1) {
      return progress / difference;
    } else {
      return (pow(base, progress) - 1) / (pow(base, difference) - 1);
    }
  }

  double? _interpolateDouble(double begin, double end, double t) {
    final diff = end - begin;
    return begin + diff * t;
  }

  Color? _interpolateColor(Color? begin, Color? end, double t) {
    final tween = ColorTween(begin: begin, end: end);
    return tween.transform(t);
  }

  @override
  T? evaluate(Map<String, dynamic> args) {
    final functionInput = input.evaluate(args)!;

    final firstStop = stops.first;
    if (functionInput <= firstStop.zoom.evaluate(args)!)
      return firstStop.value.evaluate(args);

    final lastStop = stops.last;
    if (functionInput > lastStop.zoom.evaluate(args)!)
      return lastStop.value.evaluate(args);

    final firstSmallerStopIndex = stops.lastIndexWhere(
      (stop) => stop.zoom.evaluate(args)! < functionInput,
    );
    final index = max(0, firstSmallerStopIndex);
    final smallerStop = stops[index];
    final largerStop = stops[index + 1];

    final smallerZoom = smallerStop.zoom.evaluate(args)!;
    final largerZoom = largerStop.zoom.evaluate(args)!;

    final smallerValue = smallerStop.value.evaluate(args)!;
    final largerValue = largerStop.value.evaluate(args)!;

    final t = getInterpolationFactor(functionInput, smallerZoom, largerZoom);

    if (T == double) {
      return _interpolateDouble(
        smallerValue as double,
        largerValue as double,
        t,
      ) as T?;
    }

    if (T == Color) {
      return _interpolateColor(
        smallerValue as Color?,
        largerValue as Color?,
        t,
      ) as T?;
    }
  }
}
