import 'expression.dart';

class GetPropertyExpression extends Expression {
  final _propertyName;

  GetPropertyExpression(this._propertyName) : super('get($_propertyName)');

  @override
  evaluate(EvaluationContext context) => context.getProperty(_propertyName);

  @override
  Set<String> properties() => {_propertyName};
}
