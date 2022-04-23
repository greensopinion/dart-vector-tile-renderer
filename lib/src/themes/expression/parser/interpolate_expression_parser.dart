import 'dart:math';

import '../expression.dart';
import '../interpolate_expression.dart';
import 'expression_parser.dart';

class InterpolateExpressionParser extends ExpressionComponentParser {
  InterpolateExpressionParser(ExpressionParser parser)
      : super(parser, 'interpolate');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 3;
  }

  @override
  Expression? parse(List json) {
    final inputExpression = _parseInputExpression(json);
    if (inputExpression == null) {
      return null;
    }
    final stops = _parseStops(json);
    if (stops.isEmpty) {
      return null;
    }
    final interpolationType = json[1];
    if (interpolationType is List &&
        interpolationType.length == 1 &&
        interpolationType[0] == 'linear') {
      return InterpolateLinearExpression(inputExpression, stops);
    }
    if (interpolationType is List &&
        interpolationType.length == 2 &&
        interpolationType[0] == 'exponential') {
      final base = parser.parseOptional(interpolationType[1]);
      if (base != null) {
        return InterpolateExponentialExpression(inputExpression, base, stops);
      }
    }
    if (interpolationType is List &&
        interpolationType.length == 5 &&
        interpolationType[0] == 'cubic-bezier') {
      final controlPointCoordinates =
          interpolationType.sublist(1).whereType<num>().toList();
      if (controlPointCoordinates.length == 4) {
        final first = Point<double>(controlPointCoordinates[0].toDouble(),
            controlPointCoordinates[1].toDouble());
        final second = Point<double>(controlPointCoordinates[2].toDouble(),
            controlPointCoordinates[3].toDouble());

        return InterpolateCubicBezierExpression(
            inputExpression, first, second, stops);
      }
    }
    return null;
  }

  Expression? _parseInputExpression(List json) {
    final input = json[2];
    if (input is List && input.length == 1) {
      return parser.parseOptionalPropertyOrExpression(input[0]);
    }
    return null;
  }

  List<InterpolationStop> _parseStops(List json) {
    final stops = <InterpolationStop>[];
    for (int x = 3; (x + 1 < json.length); x += 2) {
      stops.add(InterpolationStop(
          value: parser.parsePropertyOrExpression(json[x]),
          output: parser.parse(json[x + 1])));
    }
    return stops;
  }
}
