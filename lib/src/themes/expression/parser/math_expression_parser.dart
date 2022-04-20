import 'expression_parser.dart';

import '../expression.dart';
import '../math_expression.dart';

class NaryMathExpressionParser extends ExpressionComponentParser {
  String _operationName;
  BinaryOperation _operation;
  NaryMathExpressionParser(
      ExpressionParser parser, this._operationName, this._operation)
      : super(parser, _operationName);

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 2;
  }

  Expression? parse(List<dynamic> json) {
    final operands = json.sublist(1);
    final operandExpressions = operands
        .map((e) => parser.parseOptional(e))
        .whereType<Expression>()
        .toList(growable: false);
    if (operands.length != operandExpressions.length) {
      return null;
    }
    return NaryMathExpression(_operationName, _operation, operandExpressions);
  }
}
