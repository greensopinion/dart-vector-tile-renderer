import 'expression.dart';

class GetPropertyExpression extends Expression {
  final String _propertyName;

  GetPropertyExpression(this._propertyName)
      : super('get($_propertyName)', {_propertyName});

  @override
  evaluate(EvaluationContext context) => context.getProperty(_propertyName);

  @override
  bool get isConstant => false;
}

class CategoricalPropertyExpression extends Expression {
  final String _propertyName;
  final String? _default;
  final List _stops;

  CategoricalPropertyExpression(this._propertyName, this._default, this._stops)
      : super('categorical($_propertyName, $_stops)', {_propertyName});

  @override
  evaluate(EvaluationContext context) {
    final propertyValue = context.getProperty(_propertyName);
    String? tmpResult = _default;
    for (final stop in _stops) {
      if (stop is! List || stop.length != 2) {
        context.logger.warn(() => 'Could not parse categorical stop: $stop');
        continue;
      }
      final Map<String, dynamic> property = stop[0];
      if (property['zoom'] > context.zoom) break;
      if (property['value'] == propertyValue) {
        tmpResult = stop[1];
      }
    }
    return tmpResult;
  }

  @override
  bool get isConstant => false;
}
