import 'expression.dart';

class StepStop {
  final Expression value;
  final Expression output;
  final String cacheKey;

  StepStop({required this.value, required this.output})
      : cacheKey = 'stop(${value.cacheKey},${output.cacheKey})';
}

class StepExpression extends Expression {
  final Expression _input;
  final Expression _defaultOutput;
  final List<StepStop> _stops;

  StepExpression(this._input, this._defaultOutput, this._stops)
      : super(
            'step(${_input.cacheKey},${_defaultOutput.cacheKey},[${_stops.map((e) => e.cacheKey).join(',')}])');

  @override
  evaluate(EvaluationContext context) {
    var input = _input.evaluate(context);
    if (input is num) {
      final numericInput = input.toDouble();
      Expression candidateOutput = _defaultOutput;
      for (final stop in _stops) {
        final stopValue = stop.value.evaluate(context);
        if (stopValue is num) {
          final numericStopValue = stopValue.toDouble();
          if (numericStopValue >= numericInput) {
            break;
          }
          candidateOutput = stop.output;
        }
      }
      return candidateOutput.evaluate(context);
    }
  }

  @override
  Set<String> properties() {
    final accumulator = {..._input.properties()};
    accumulator.addAll(_defaultOutput.properties());
    for (final stop in _stops) {
      accumulator.addAll(stop.value.properties());
      accumulator.addAll(stop.output.properties());
    }
    return accumulator;
  }
}
