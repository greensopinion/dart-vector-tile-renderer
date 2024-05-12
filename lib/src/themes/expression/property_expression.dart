import 'expression.dart';
import 'literal_expression.dart';

class GetPropertyExpression extends Expression {
  final String _propertyName;

  GetPropertyExpression(this._propertyName)
      : super('get($_propertyName)', {_propertyName});

  @override
  evaluate(EvaluationContext context) => context.getProperty(_propertyName);

  @override
  bool get isConstant => false;
}

/// A function that returns the output value of the stop equal to the
/// function input.
///
/// As of v0.41.0, property expressions is the preferred method for
/// styling features based on zoom level or the feature's properties.
/// Zoom and property functions will be phased out in a future
/// style specification.
class CategoricalPropertyExpression extends Expression {
  /// If specified, the function will take the specified feature property
  /// as an input.
  final LiteralExpression? propertyName;

  /// When the feature value does not match any of the stop domain values.
  final LiteralExpression? defaultValue;

  /// An alternating list of one input and one output value. Stop output
  /// values must be literal values (in other words not functions or
  /// expressions), and appropriate for the property. For example, stop output
  /// values for a fill-color function property must be colors.
  final List stops;

  CategoricalPropertyExpression({
    required this.propertyName,
    required this.defaultValue,
    required this.stops,
  }) : super('categorical($propertyName)',
            stops.map((e) => e.toString()).toSet());

  @override
  evaluate(EvaluationContext context) {
    final propertyName = this.propertyName?.evaluate(context);
    if (propertyName == null) return defaultValue?.evaluate(context);

    final propertyValue = context.getProperty(propertyName!);
    dynamic tmpResult;
    for (var i = 0; i < stops.length; i += 2) {
      final input = stops[i];
      final inputZoom = input['zoom'];
      if (inputZoom is! int) continue;
      if (input['zoom'] > context.zoom) break;

      final output = stops[i + 1];
      if (input['value'] == propertyValue) {
        tmpResult = output;
      }
    }
    return tmpResult ?? defaultValue?.evaluate(context);
  }

  @override
  bool get isConstant => false;
}
