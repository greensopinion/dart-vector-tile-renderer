import 'package:vector_tile/vector_tile_value.dart';

import 'expression.dart';

class ArgumentExpression<T> extends Expression<T> {
  final String key;
  ArgumentExpression(this.key);

  @override
  T? evaluate(Map<String, dynamic> args) {
    final value = args[key];

    if (value is T?) return value;

    if (T == double && value is num) {
      return value.toDouble() as T;
    }

    if (value is VectorTileValue) {
      switch (T) {
        case double:
          return value.doubleValue as T?;
        case bool:
          return value.boolValue as T?;
        case String:
          return value.stringValue as T?;
      }
    }

    return null;
  }
}
