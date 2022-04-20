import '../expression.dart';
import '../step_expression.dart';
import 'expression_parser.dart';

class StepExpressionParser extends ExpressionComponentParser {
  StepExpressionParser(ExpressionParser parser) : super(parser, 'step');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 2;
  }

  @override
  Expression? parse(List json) {
    final inputExpression = _parseInputExpression(json);
    if (inputExpression == null) {
      return null;
    }
    final defaultValueExpression = parser.parseOptional(json[2]);
    if (defaultValueExpression == null) {
      return null;
    }
    final stops = _parseStops(json);
    if (stops.isEmpty) {
      return null;
    }
    return StepExpression(inputExpression, defaultValueExpression, stops);
  }

  Expression? _parseInputExpression(List json) {
    final input = json[1];
    if (input is List && input.length == 1) {
      return parser.parseOptionalPropertyOrExpression(input[0]);
    }
    return parser.parseOptional(input);
  }

  List<StepStop> _parseStops(List json) {
    final stops = <StepStop>[];
    for (int x = 3; (x + 1 < json.length); x += 2) {
      stops.add(StepStop(
          value: parser.parse(json[x]), output: parser.parse(json[x + 1])));
    }
    return stops;
  }
}
