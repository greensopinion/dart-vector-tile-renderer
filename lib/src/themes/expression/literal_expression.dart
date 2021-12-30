import 'expression.dart';

class LiteralExpression extends Expression {
  final _literal;

  LiteralExpression(this._literal);

  @override
  evaluate(EvaluationContext context) => _literal;
}
