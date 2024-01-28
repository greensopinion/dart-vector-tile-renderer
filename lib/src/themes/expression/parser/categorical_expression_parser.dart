import 'package:vector_tile_renderer/src/themes/expression/property_expression.dart';

import '../expression.dart';
import 'expression_parser.dart';

class CategoricalExpressionParser extends ExpressionComponentParser {
  CategoricalExpressionParser(ExpressionParser parser)
      : super(parser, 'categorical');

  @override
  Expression? parse(List<dynamic> json) {
    return CategoricalPropertyExpression(
      propertyName: json[1],
      defaultValue: json[2],
      stops: json.sublist(3),
    );
  }
}
