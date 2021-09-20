// typedef FunctionExpression<T> = T? Function([Map<String, dynamic>? args]);

T getValue<T>(dynamic expression, [Map<String, dynamic>? args]) {
  if (expression is T) return expression;
  if (expression is String) return args?[expression];
  if (expression is List) {
    final first = expression.first;
    final name = first == 'get' ? expression[1] : first;
    return args?[name];
  }

  throw Exception('Could not get value from $expression and args $args');
}

abstract class Expression<T> {
  T? evaluate(Map<String, dynamic> args);
}
