import 'expression.dart';

class GetPropertyExpression extends Expression {
  final _propertyName;

  GetPropertyExpression(this._propertyName)
      : super('get($_propertyName)', {_propertyName});

  @override
  evaluate(EvaluationContext context) => context.getProperty(_propertyName);

  @override
  bool get isConstant => false;
}
