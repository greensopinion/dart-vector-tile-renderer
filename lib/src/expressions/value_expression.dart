import 'expression.dart';

class ValueExpression<T> extends Expression<T> {
  final T? _value;
  ValueExpression(this._value);

  T? evaluate(Map<String, dynamic> values) => _value;
}
