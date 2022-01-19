import 'expression.dart';

class ComparisonExpression extends Expression {
  final Expression _first;
  final Expression _second;
  final bool Function(num, num) _comparison;

  ComparisonExpression(
      this._comparison, String comparisonKey, this._first, this._second)
      : super('(${_first.cacheKey} $comparisonKey ${_second.cacheKey})');

  @override
  evaluate(EvaluationContext context) {
    final first = _first.evaluate(context);
    final second = _second.evaluate(context);
    if (first is num && second is num) {
      return _comparison(first, second);
    }
    return false;
  }

  @override
  Set<String> properties() => {..._first.properties(), ..._second.properties()};
}

class MatchExpression extends Expression {
  final Expression _input;
  final List<List<Expression>> _values;
  final List<Expression> _outputs;

  MatchExpression(this._input, this._values, this._outputs)
      : super(
            'match(${_input.cacheKey},${_values.map((e) => "[${e.map((i) => i.cacheKey).join(',')}]").join(',')},${_outputs.map((e) => e.cacheKey).join(',')})');

  @override
  evaluate(EvaluationContext context) {
    final input = _input.evaluate(context);
    if (input != null) {
      for (int index = 0;
          index < _values.length && index < _outputs.length;
          ++index) {
        if (_values[index].any((e) => e.evaluate(context) == input)) {
          return _outputs[index].evaluate(context);
        }
      }
      if (_outputs.length > _values.length) {
        return _outputs[_values.length].evaluate(context);
      }
    }
  }

  @override
  Set<String> properties() {
    final accumulator = {..._input.properties()};
    for (final value in _values) {
      for (final delegate in value) {
        accumulator.addAll(delegate.properties());
      }
    }
    for (final output in _outputs) {
      accumulator.addAll(output.properties());
    }
    return accumulator;
  }
}
