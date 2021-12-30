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
