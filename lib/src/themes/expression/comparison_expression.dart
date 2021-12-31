import 'expression.dart';

class ComparisonExpression extends Expression {
  final Expression _first;
  final Expression _second;
  final bool Function(num, num) _comparison;

  ComparisonExpression(this._comparison, this._first, this._second);

  @override
  evaluate(EvaluationContext context) {
    final first = _first.evaluate(context);
    final second = _second.evaluate(context);
    if (first is num && second is num) {
      return _comparison(first, second);
    }
    return false;
  }
}

class MatchExpression extends Expression {
  final Expression _input;
  final List<List<Expression>> _values;
  final List<Expression> _outputs;

  MatchExpression(this._input, this._values, this._outputs);

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
}
