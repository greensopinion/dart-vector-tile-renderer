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
      return interpolate(
          context, numericInput, valueBelow, stopBelow, valueAbove, stopAbove);
    }
  }

  interpolate(
      EvaluationContext context,
      double? input,
      double? valueBelow,
      InterpolationStop? stopBelow,
      double? valueAbove,
      InterpolationStop? stopAbove);

  @override
  Set<String> properties() {
    final accumulator = {..._input.properties()};
    for (final stop in _stops) {
      accumulator.addAll(stop.value.properties());
      accumulator.addAll(stop.output.properties());
    }
    return accumulator;
  }
}

class InterpolateLinearExpression extends InterpolateExpression {
  InterpolateLinearExpression(Expression input, List<InterpolationStop> stops)
      : super(input, 'linear', stops);

  @override
  interpolate(
      EvaluationContext context,
      double? input,
      double? valueBelow,
      InterpolationStop? stopBelow,
      double? valueAbove,
      InterpolationStop? stopAbove) {
    if (input != null) {
      final belowOutput = stopBelow?.output.evaluate(context);
      final aboveOutput = stopAbove?.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (valueBelow != null &&
          valueAbove != null &&
          belowOutput is num &&
          aboveOutput is num) {
        return _exponentialInterpolation(input, 1, valueBelow, valueAbove,
            belowOutput.toDouble(), aboveOutput.toDouble());
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
      double? valueBelow,
      InterpolationStop? stopBelow,
      double? valueAbove,
      InterpolationStop? stopAbove) {
    if (input != null) {
      final belowOutput = stopBelow?.output.evaluate(context);
      final aboveOutput = stopAbove?.output.evaluate(context);
      if (aboveOutput == null) {
        return belowOutput;
      } else if (belowOutput == null) {
        return null;
      } else if (valueBelow != null &&
          valueAbove != null &&
          belowOutput is num &&
          aboveOutput is num) {
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
    factor = _factorCalculator.calculate(base, progress, difference);
  }
  return (lowOutput * (1 - factor)) + (highOutput * factor);
}

final _factorCalculator = _PowFactorCalculator();

class _PowFactorCalculator {
  final _results = <_PowFactorResult>[];
  final _maxResults = 5;

  double calculate(double base, double progress, double difference) {
    int offset = 0;
    for (final result in _results) {
      if (result.base == base &&
          result.progress == progress &&
          result.difference == difference) {
        if (offset > 0) {
          _results.remove(offset);
          _results.insert(0, result);
        }
        return result.result;
      }
      ++offset;
    }
    final result = _PowFactorResult(base, progress, difference,
        (pow(base, progress) - 1) / (pow(base, difference) - 1));
    if (_results.length >= _maxResults) {
      _results.removeLast();
    }
    _results.insert(0, result);
    return result.result;
  }
}

class _PowFactorResult {
  final double base;
  final double progress;
  final double difference;
  final double result;

  _PowFactorResult(this.base, this.progress, this.difference, this.result);
}
