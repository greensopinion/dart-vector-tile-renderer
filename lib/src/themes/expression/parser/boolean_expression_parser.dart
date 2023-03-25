import '../boolean_expression.dart';
import '../expression.dart';
import 'expression_parser.dart';

class ToBooleanExpressionParser extends ExpressionComponentParser {
  ToBooleanExpressionParser(ExpressionParser parser)
      : super(parser, 'to-boolean');

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
    if (values.length != valueExpressions.length || values.length != 1) {
      return null;
    }
    return ToBooleanExpression(valueExpressions.first);
  }
}
