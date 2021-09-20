import 'package:vector_tile_renderer/src/expressions/coalesce_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class CoalesceParser<T> extends ExpressionParser<T> {
  @override
  Expression<T>? parse(data) {
    if (data is! List) return null;

    final delegates =
        data.skip(1).map((i) => Parsers.parse<T>(i)).whereType<Expression<T>>();
    return CoalesceExpression(delegates);
  }
}
