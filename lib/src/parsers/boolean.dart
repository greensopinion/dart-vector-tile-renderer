import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'parser.dart';

class BooleanParser extends Parser<bool> {
  @override
  Expression<bool>? parseSpecial(data) {
    if (data == "true") return ValueExpression(true);
    if (data == "false") return ValueExpression(false);
  }
}
