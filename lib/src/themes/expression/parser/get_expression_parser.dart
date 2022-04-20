import '../expression.dart';
import '../property_expression.dart';
import 'expression_parser.dart';

class GetExpressionParser extends ExpressionComponentParser {
  GetExpressionParser(ExpressionParser parser) : super(parser, 'get');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    return GetPropertyExpression(json[1]);
  }
}
