import 'dart:math';

import 'step_expression.dart';

import '../../logger.dart';
import 'coalesce_expression.dart';
import 'comparison_expression.dart';
import 'expression.dart';
import 'interpolate_expression.dart';
import 'literal_expression.dart';
import 'math_expression.dart';
import 'property_expression.dart';

// https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/

typedef ExpressionFunction = Expression Function();

class ExpressionParser {
  final Logger logger;
  Map<String, _ExpressionParser> _parserByOperator = {};
  ExpressionParser(this.logger) {
    _register(_GetExpressionParser(this));
    _register(_HasExpressionParser(this));
    _register(_NotHasExpressionParser(this));
    _register(_InExpressionParser(this));
    _register(_NotInExpressionParser(this));
    _register(_NotExpressionParser(this));
    _register(_EqualsExpressionParser(this));
    _register(_NotEqualsExpressionParser(this));
    _register(_ComparisonExpressionParser(
        this, '<', (first, second) => first < second));
    _register(_ComparisonExpressionParser(
        this, '>', (first, second) => first > second));
    _register(_ComparisonExpressionParser(
        this, '<=', (first, second) => first <= second));
    _register(_ComparisonExpressionParser(
        this, '>=', (first, second) => first >= second));
    _register(_AllExpressionParser(this));
    _register(_AnyExpressionParser(this));
    _register(_InterpolateExpressionParser(this));
    _register(_StepExpressionParser(this));
    _register(_ToStringExpressionParser(this));
    _register(_MatchExpressionParser(this));
    _register(_GeometryTypeExpressionParser(this));
    _register(_CoalesceExpressionParser(this));
    _register(_NaryMathExpressionParser(this, '*', (a, b) => a * b));
    _register(_NaryMathExpressionParser(this, '/', (a, b) => a / b));
    _register(_NaryMathExpressionParser(this, '+', (a, b) => a + b));
    _register(_NaryMathExpressionParser(this, '-', (a, b) => a - b));
    _register(_NaryMathExpressionParser(this, '%', (a, b) => a % b));
    _register(_NaryMathExpressionParser(this, '^', pow));
  }

  Set<String> supportedOperators() => _parserByOperator.keys.toSet();

  Expression parse(dynamic json, {ExpressionFunction? whenNull}) {
    if (json == null && whenNull != null) {
      return whenNull();
    }
    final expression = parseOptional(json);
    return _expressionChecked(expression, json);
  }

  Expression? parseOptional(dynamic json) {
    if (json is String) {
      return _parseString(json);
    }
    if (json is num || json is bool || json == null) {
      return LiteralExpression(json);
    }
    if (json is List && json.length > 0) {
      final operator = json[0];
      final delegate = _parserByOperator[operator];
      if (delegate != null && delegate.matches(json)) {
        final expression = delegate.parse(json);
        if (expression != null) {
          return expression;
        }
      }
    }
    if (json is Map) {
      final base = json['base'];
      final stops = json['stops'];
      if (stops is List) {
        if (base == 1) {
          return parseOptional([
            'interpolate',
            ['linear'],
            ['zoom'],
            ..._flattenStops(stops)
          ]);
        } else {
          return parseOptional([
            'interpolate',
            ['exponential', base],
            ['zoom'],
            ..._flattenStops(stops)
          ]);
        }
      }
    }
    logger.warn(() => 'Unsupported expression syntax: $json');
    return null;
  }

  List _flattenStops(List stops) {
    final flat = [];
    for (final stop in stops) {
      if (stop is List) {
        flat.addAll(stop);
      } else {
        flat.add(stop);
      }
    }
    return flat;
  }

  void _register(_ExpressionParser delegate) {
    if (_parserByOperator.containsKey(delegate.operator)) {
      throw Exception('duplicate operator ${delegate.operator}');
    }
    _parserByOperator[delegate.operator] = delegate;
  }

  Expression? _parseOptionalPropertyOrExpression(json) {
    if (json is String) {
      return parseOptional(['get', json]);
    }
    return parseOptional(json);
  }

  Expression _parsePropertyOrExpression(json) {
    Expression? expression;
    if (json is String) {
      expression = parseOptional(['get', json]);
    }
    expression = parseOptional(json);
    return _expressionChecked(expression, json);
  }

  Expression _expressionChecked(Expression? expression, json) {
    if (expression == null) {
      logger.warn(() => 'Unsupported expression: $json');
      return UnsupportedExpression(json);
    }
    return expression;
  }

  Expression? _parseString(String json) {
    final match = RegExp(r'\{(.+?)\}').firstMatch(json);
    if (match != null) {
      final propertyName = match.group(1);
      if (propertyName != null) {
        return GetPropertyExpression(propertyName);
      }
    }
    return LiteralExpression(json);
  }
}

abstract class _ExpressionParser {
  final ExpressionParser parser;
  final String operator;

  _ExpressionParser(this.parser, this.operator);

  bool matches(List<dynamic> json) {
    return json.length > 0 && json[0] == operator;
  }

  Expression? parse(List<dynamic> json);
}

class _GetExpressionParser extends _ExpressionParser {
  _GetExpressionParser(ExpressionParser parser) : super(parser, 'get');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    return GetPropertyExpression(json[1]);
  }
}

class _ToStringExpressionParser extends _ExpressionParser {
  _ToStringExpressionParser(ExpressionParser parser)
      : super(parser, 'to-string');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  Expression? parse(List<dynamic> json) {
    final delegate = parser.parseOptional(json[1]);
    if (delegate == null) {
      return null;
    }
    return ToStringExpression(delegate);
  }
}

class _HasExpressionParser extends _ExpressionParser {
  _HasExpressionParser(ExpressionParser parser) : super(parser, 'has');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      return NotNullExpression(getExpression);
    }
    return null;
  }
}

class _NotHasExpressionParser extends _ExpressionParser {
  _NotHasExpressionParser(ExpressionParser parser) : super(parser, '!has');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      return NotExpression(NotNullExpression(getExpression));
    }
    return null;
  }
}

class _InExpressionParser extends _ExpressionParser {
  _InExpressionParser(ExpressionParser parser) : super(parser, 'in');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 3 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      final values = json.sublist(2);
      return InExpression(getExpression, values);
    }
    return null;
  }
}

class _NotInExpressionParser extends _ExpressionParser {
  _NotInExpressionParser(ExpressionParser parser) : super(parser, '!in');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 3 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      final values = json.sublist(2);
      return NotExpression(InExpression(getExpression, values));
    }
    return null;
  }
}

class _NotExpressionParser extends _ExpressionParser {
  _NotExpressionParser(ExpressionParser parser) : super(parser, '!');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  Expression? parse(List<dynamic> json) {
    Expression? second = parser._parseOptionalPropertyOrExpression(json[1]);
    if (second != null) {
      return NotExpression(second);
    }
    return null;
  }
}

class _EqualsExpressionParser extends _ExpressionParser {
  _EqualsExpressionParser(ExpressionParser parser) : super(parser, '==');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  Expression? parse(List<dynamic> json) {
    final firstOperand = json[1];
    final secondOperand = json[2];
    Expression? first = parser._parseOptionalPropertyOrExpression(firstOperand);
    Expression? second = parser.parseOptional(secondOperand);
    if (first != null && second != null) {
      return EqualsExpression(first, second);
    }
    return null;
  }
}

class _NotEqualsExpressionParser extends _ExpressionParser {
  _NotEqualsExpressionParser(ExpressionParser parser) : super(parser, '!=');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  Expression? parse(List<dynamic> json) {
    final delegate = parser.parseOptional(['==', json[1], json[2]]);
    if (delegate != null) {
      return NotExpression(delegate);
    }
    return null;
  }
}

class _ComparisonExpressionParser extends _ExpressionParser {
  final bool Function(num, num) _comparison;

  _ComparisonExpressionParser(
      ExpressionParser parser, String operator, this._comparison)
      : super(parser, operator);

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  Expression? parse(List<dynamic> json) {
    final firstOperand = json[1];
    final secondOperand = json[2];
    final first = parser._parseOptionalPropertyOrExpression(firstOperand);
    final second = parser.parseOptional(secondOperand);
    if (first != null && second != null) {
      return ComparisonExpression(_comparison, operator, first, second);
    }
    return null;
  }
}

class _AllExpressionParser extends _ExpressionParser {
  _AllExpressionParser(ExpressionParser parser) : super(parser, 'all');

  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AllExpression(
        delegates.whereType<Expression>().toList(growable: false));
  }
}

class _AnyExpressionParser extends _ExpressionParser {
  _AnyExpressionParser(ExpressionParser parser) : super(parser, 'any');

  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AnyExpression(
        delegates.whereType<Expression>().toList(growable: false));
  }
}

class _MatchExpressionParser extends _ExpressionParser {
  _MatchExpressionParser(ExpressionParser parser) : super(parser, 'match');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 3;
  }

  Expression? parse(List<dynamic> json) {
    final firstOperand = json[1];
    final input = parser.parseOptional(firstOperand);
    if (input == null) {
      return null;
    }
    List<List<Expression>> values = [];
    List<Expression> outputs = [];
    for (int x = 2; x < json.length; x += 2) {
      if (x + 1 < json.length) {
        final jsonValues = json[x];
        final matchValues = jsonValues is List
            ? jsonValues.map((e) => parser.parseOptional(e)).toList()
            : [parser.parseOptional(jsonValues)];
        final output = parser.parseOptional(json[x + 1]);
        if (matchValues.any((e) => e == null) || output == null) {
          return null;
        }
        values.add(matchValues.whereType<Expression>().toList(growable: false));
        outputs.add(output);
      } else {
        final output = parser.parseOptional(json[x]);
        if (output == null) {
          return null;
        }
        outputs.add(output);
      }
    }

    return MatchExpression(input, values, outputs);
  }
}

class _InterpolateExpressionParser extends _ExpressionParser {
  _InterpolateExpressionParser(ExpressionParser parser)
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
      return parser._parseOptionalPropertyOrExpression(input[0]);
    }
    return null;
  }

  List<InterpolationStop> _parseStops(List json) {
    final stops = <InterpolationStop>[];
    for (int x = 3; (x + 1 < json.length); x += 2) {
      stops.add(InterpolationStop(
          value: parser._parsePropertyOrExpression(json[x]),
          output: parser.parse(json[x + 1])));
    }
    return stops;
  }
}

class _StepExpressionParser extends _ExpressionParser {
  _StepExpressionParser(ExpressionParser parser) : super(parser, 'step');

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
      return parser._parseOptionalPropertyOrExpression(input[0]);
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

class _CoalesceExpressionParser extends _ExpressionParser {
  _CoalesceExpressionParser(ExpressionParser parser)
      : super(parser, 'coalesce');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 1;
  }

  @override
  Expression? parse(List json) {
    final values = json.sublist(1);
    final valueExpressions = values
        .map((e) => parser.parseOptional(e))
        .whereType<Expression>()
        .toList(growable: false);
    if (values.length != valueExpressions.length) {
      return null;
    }
    return CoalesceExpression(valueExpressions);
  }
}

class _GeometryTypeExpressionParser extends _ExpressionParser {
  _GeometryTypeExpressionParser(ExpressionParser parser)
      : super(parser, 'geometry-type');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 1;
  }

  Expression? parse(List<dynamic> json) {
    return GetPropertyExpression("\$type");
  }
}

class _NaryMathExpressionParser extends _ExpressionParser {
  String _operationName;
  BinaryOperation _operation;
  _NaryMathExpressionParser(
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
