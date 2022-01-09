import 'dart:math';

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
            'interpolate(${_input.cacheKey},$interpolation,[${_stops.map((e) => e.cacheKey).join(',')}])');

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
      : super(input, 'linear', stops);

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
      : super(input, 'exponential(${base.cacheKey})', stops);

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
    factor = _factorCalculator.calculate(base, progress, difference);
  }
  return (lowOutput * (1 - factor)) + (highOutput * factor);
}

final _factorCalculator = _PowFactorCalculator();

class _PowFactorCalculator {
  final _results = <_PowFactorResult>[];
  final _maxResults = 5;

  double calculate(num base, num progress, num difference) {
    for (final result in _results) {
      if (result.base == base &&
          result.progress == progress &&
          result.difference == difference) {
        return result.result;
      }
    }
    final result = _PowFactorResult(base, progress, difference,
        (pow(base, progress) - 1) / (pow(base, difference) - 1));
    if (_results.length >= _maxResults) {
      _results.removeAt(0);
    }
    _results.insert(0, result);
    return result.result;
  }
}

class _PowFactorResult {
  final num base;
  final num progress;
  final num difference;
  final double result;

  _PowFactorResult(this.base, this.progress, this.difference, this.result);
}
