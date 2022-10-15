import '../expression.dart';
import '../numeric_expression.dart';
import 'expression_parser.dart';

class ToNumberExpressionParser extends ExpressionComponentParser {
  ToNumberExpressionParser(ExpressionParser parser)
      : super(parser, 'to-number');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 2;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final values = json.sublist(1);
    final valueExpressions = values
        .map((e) => parser.parseOptional(e))
        .whereType<Expression>()
        .toList(growable: false);
    if (values.length != valueExpressions.length) {
      return null;
    }
    return ToNumberExpression(valueExpressions);
  }
}
