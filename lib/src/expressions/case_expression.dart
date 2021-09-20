import 'expression.dart';

class Case<T> {
  final Expression<bool> condition;
  final Expression<T>? value;

  Case(this.condition, this.value);
}

class CaseExpression<T> extends Expression<T> {
  final Iterable<Case<T>> _cases;
  final Expression<T>? _fallback;

  CaseExpression(this._cases, this._fallback);

  @override
  T? evaluate(Map<String, dynamic> args) {
    for (final $case in _cases) {
      final boolExpression = $case.condition.evaluate(args) ?? false;
      if (boolExpression) {
        return $case.value?.evaluate(args);
      }
    }

    return _fallback?.evaluate(args);
  }
}
