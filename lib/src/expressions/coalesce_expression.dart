import 'expression.dart';

class CoalesceExpression<T> extends Expression<T> {
  final Iterable<Expression<T>> _delegates;

  CoalesceExpression(this._delegates);

  @override
  T? evaluate(Map<String, dynamic> args) {
    for (final delegate in _delegates) {
      final result = delegate.evaluate(args);
      if (result != null) return result;
    }

    return null;
  }
}
