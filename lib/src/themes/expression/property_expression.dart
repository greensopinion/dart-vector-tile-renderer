import 'package:vector_tile_renderer/src/themes/expression/expression.dart';

class GetPropertyExpression extends Expression {
  final _propertyName;

  GetPropertyExpression(this._propertyName);

  @override
  evaluate(EvaluationContext context) => context.getProperty(_propertyName);
}
