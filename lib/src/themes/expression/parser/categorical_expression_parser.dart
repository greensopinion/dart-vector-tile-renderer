import 'package:vector_tile_renderer/src/themes/expression/property_expression.dart';

import '../expression.dart';
import 'expression_parser.dart';

class CategoricalExpressionParser extends ExpressionComponentParser {
  CategoricalExpressionParser(ExpressionParser parser)
      : super(parser, 'categorical');

  @override
  Expression? parse(List<dynamic> json) {
    // [0] expression type
    // [1] property name
    // [2] default value
    // [3:] pair of stops
    if (json.length < 3 || json.length.isEven) {
      throw Exception(
        'The amount of categorical expression of the theme is malformed',
      );
    }

    return CategoricalPropertyExpression(
      propertyName: json[1],
      defaultValue: json[2],
      stops: json.sublist(3),
    );
  }
}
