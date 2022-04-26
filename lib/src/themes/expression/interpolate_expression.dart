import 'dart:math';

import 'cubic_bezier.dart';
import 'expression.dart';

class InterpolationStop {
  final Expression value;
  final Expression output;
  final String cacheKey;

  InterpolationStop({required this.value, required this.output})
      : cacheKey = 'stop(${value.cacheKey},${output.cacheKey})';
}

abstract class InterpolateExpression extends Expression {
  final Expression _input;
  final List<InterpolationStop> _stops;

  InterpolateExpression(this._input, String interpolation, this._stops)
      : super(
            'interpolate(${_input.cacheKey},$interpolation,[${_stops.map((e) => e.cacheKey).join(',')}])',
            _createProperties(_input, _stops));

  @override
  bool get isConstant => false;

  @override
  evaluate(EvaluationContext context) {
    var input = _input.evaluate(context);
    if (input is num) {
      final numericInput = input.toDouble();
      InterpolationStop? stopBelow;
      InterpolationStop? stopAbove;
      double? valueBelow;
      double? valueAbove;
      for (final stop in _stops) {
        final stopValue = stop.value.evaluate(context);
        if (stopValue is num) {
          final numericStopValue = stopValue.toDouble();
          if (numericStopValue <= numericInput) {
            valueBelow = numericStopValue;
            stopBelow = stop;
          } else if (numericStopValue > numericInput) {
            valueAbove = numericStopValue;
            stopAbove = stop;
            break;
          }
        }
      }
      if (valueBelow != null && valueAbove != null) {
        return interpolate(context, numericInput, valueBelow, stopBelow!,
            valueAbove, stopAbove!);
      } else if (valueBelow != null) {
        return stopBelow?.output.evaluate(context);
      } else {
        return stopAbove?.output.evaluate(context);
      }
    }
  }

  interpolate(
      EvaluationContext context,
      double? input,
      double valueBelow,
      InterpolationStop stopBelow,
      double valueAbove,
      InterpolationStop stopAbove);
}

@override
Set<String> _createProperties(Expression input, List<InterpolationStop> stops) {
  final accumulator = {...input.properties()};
  for (final stop in stops) {
    accumulator.addAll(stop.value.properties());
    accumulator.addAll(stop.output.properties());
  }
  return accumulator;
}

class InterpolateLinearExpression extends InterpolateExpression {
  InterpolateLinearExpression(Expression input, List<InterpolationStop> stops)
      : super(input, 'linear', stops);

  @override
  interpolate(
      EvaluationContext context,
      double? input,
      double valueBelow,
      InterpolationStop stopBelow,
      double valueAbove,
      InterpolationStop stopAbove) {
    if (input != null) {
      final belowOutput = stopBelow.output.evaluate(context);
      final aboveOutput = stopAbove.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (belowOutput is num && aboveOutput is num) {
        return _exponentialInterpolation(input, 1, valueBelow, valueAbove,
            belowOutput.toDouble(), aboveOutput.toDouble());
      } else {
        // could be a color, this is a stop-gap (e.g until we support hcl)
        return belowOutput;
      }
    }
  }
}

class InterpolateExponentialExpression extends InterpolateExpression {
  Expression base;

  InterpolateExponentialExpression(
      Expression input, this.base, List<InterpolationStop> stops)
      : super(input, 'exponential(${base.cacheKey})', stops);

  @override
  interpolate(
      EvaluationContext context,
      double? input,
      double valueBelow,
      InterpolationStop stopBelow,
      double valueAbove,
      InterpolationStop stopAbove) {
    if (input != null) {
      final belowOutput = stopBelow.output.evaluate(context);
      final aboveOutput = stopAbove.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (belowOutput is num && aboveOutput is num) {
        final baseValue = base.evaluate(context);
        if (baseValue is num) {
          return _exponentialInterpolation(
              input,
              baseValue.toDouble(),
              valueBelow,
              valueAbove,
              belowOutput.toDouble(),
              aboveOutput.toDouble());
        }
      }
    }
  }
}

double _exponentialInterpolation(double input, double base, double lowValue,
    double highValue, double lowOutput, double highOutput) {
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

class InterpolateCubicBezierExpression extends InterpolateExpression {
  final Point<double> _firstControlPoint;
  final Point<double> _secondControlPoint;
  late final CubicBezier _bezier;

  InterpolateCubicBezierExpression(Expression input, this._firstControlPoint,
      this._secondControlPoint, List<InterpolationStop> stops)
      : super(
            input,
            'cubicBezier(${_firstControlPoint.x},${_firstControlPoint.y},${_secondControlPoint.x},${_secondControlPoint.y})',
            stops) {
    _bezier = CubicBezier(_firstControlPoint, _secondControlPoint);
  }

  @override
  interpolate(
      EvaluationContext context,
      double? input,
      double valueBelow,
      InterpolationStop stopBelow,
      double valueAbove,
      InterpolationStop stopAbove) {
    if (input != null) {
      final difference = valueAbove - valueBelow;
      final progress = input - valueBelow;
      final factor = progress / difference;
      final outputBelow = stopBelow.output.evaluate(context);
      final outputAbove = stopAbove.output.evaluate(context);
      if (outputBelow is num && outputAbove is num) {
        final t = _bezier.solve(factor.toDouble());
        return (outputBelow.toDouble() * (1 - t)) +
            (outputAbove.toDouble() * t);
      }
    }
    return null;
  }
}
