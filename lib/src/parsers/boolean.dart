import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'parser.dart';

class BooleanParser extends ExpressionParser<bool> {
  @override
  Expression<bool>? parse(data) {
    if (data == 'true') return ValueExpression(true);
    if (data == 'false') return ValueExpression(false);
  }
}
