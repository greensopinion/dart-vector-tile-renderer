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
        var difference = valueAbove - valueBelow;
        var progress = input - valueBelow;
        if (difference == 0 || progress == 0) {
          return belowOutput;
        } else {
          final factor = progress / difference;
          final outputDifference = aboveOutput - belowOutput;
          final exact = belowOutput + (factor * outputDifference);
          return (exact * 1000).roundToDouble() / 1000;
        }
      }
    }
  }
}
