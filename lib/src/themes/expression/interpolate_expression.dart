import 'dart:math';

import 'expression.dart';

class InterpolationStop {
  final Expression value;
  final Expression output;

  InterpolationStop({required this.value, required this.output});
}

abstract class InterpolateExpression extends Expression {
  final Expression _input;
  final List<InterpolationStop> _stops;

  InterpolateExpression(this._input, this._stops);

  @override
  evaluate(EvaluationContext context) {
    final input = _input.evaluate(context);
    if (input != null) {
      InterpolationStop? stopBelow;
      InterpolationStop? stopAbove;
      var valueBelow;
      var valueAbove;
      for (final stop in _stops) {
        final stopValue = stop.value.evaluate(context);
        if (stopValue <= input) {
          valueBelow = stopValue;
          stopBelow = stop;
        } else if (stopValue > input) {
          valueAbove = stopValue;
          stopAbove = stop;
          break;
        }
      }
      return interpolate(
          context, input, valueBelow, stopBelow, valueAbove, stopAbove);
    }
  }

  interpolate(EvaluationContext context, input, valueBelow,
      InterpolationStop? stopBelow, valueAbove, InterpolationStop? stopAbove);
}

class InterpolateLinearExpression extends InterpolateExpression {
  InterpolateLinearExpression(Expression input, List<InterpolationStop> stops)
      : super(input, stops);

  @override
  interpolate(EvaluationContext context, input, valueBelow,
      InterpolationStop? stopBelow, valueAbove, InterpolationStop? stopAbove) {
    if (input is num) {
      final belowOutput = stopBelow?.output.evaluate(context);
      final aboveOutput = stopAbove?.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (valueBelow is num &&
          valueAbove is num &&
          belowOutput is num &&
          aboveOutput is num) {
        return _exponentialInterpolation(
            input, 1, valueBelow, valueAbove, belowOutput, aboveOutput);
      }
    }
  }
}

class InterpolateExponentialExpression extends InterpolateExpression {
  Expression base;

  InterpolateExponentialExpression(
      Expression input, this.base, List<InterpolationStop> stops)
      : super(input, stops);

  @override
  interpolate(EvaluationContext context, input, valueBelow,
      InterpolationStop? stopBelow, valueAbove, InterpolationStop? stopAbove) {
    if (input is num) {
      final belowOutput = stopBelow?.output.evaluate(context);
      final aboveOutput = stopAbove?.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (valueBelow is num &&
          valueAbove is num &&
          belowOutput is num &&
          aboveOutput is num) {
        final baseValue = base.evaluate(context);
        if (baseValue is num) {
          return _exponentialInterpolation(input, baseValue, valueBelow,
              valueAbove, belowOutput, aboveOutput);
        }
      }
    }
  }
}

num _exponentialInterpolation(num input, num base, num lowValue, num highValue,
    num lowOutput, num highOutput) {
  var difference = highValue - lowValue;
  var progress = input - lowValue;
  if (difference <= 0.001 || progress <= 0) {
    return lowOutput;
  }
  double factor;
  if (base >= 0.99 && base <= 1.01) {
    factor = progress / difference;
  } else {
    factor = (pow(base, progress) - 1) / (pow(base, difference) - 1);
  }
  return (lowOutput * (1 - factor)) + (highOutput * factor);
}
