import 'package:vector_tile_renderer/src/themes/expression/interpolate_expression.dart';

import 'comparison_expression.dart';
import 'property_expression.dart';

import '../../logger.dart';
import 'expression.dart';
import 'literal_expression.dart';

// https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/

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
  }

  Set<String> supportedOperators() => _parserByOperator.keys.toSet();

  Expression parse(dynamic json) {
    final expression = parseOptional(json);
    return _expressionChecked(expression, json);
  }

  Expression? parseOptional(dynamic json) {
    if (json is String || json is num || json is bool || json == null) {
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
      logger.warn(() => 'Unsupported expression syntax: $json');
      return UnsupportedExpression(json);
    }
    return expression;
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
      return ComparisonExpression(_comparison, first, second);
    }
  }
}

class _AllExpressionParser extends _ExpressionParser {
  _AllExpressionParser(ExpressionParser parser) : super(parser, 'all');

  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AllExpression(delegates.whereType<Expression>().toList());
  }
}

class _AnyExpressionParser extends _ExpressionParser {
  _AnyExpressionParser(ExpressionParser parser) : super(parser, 'any');

  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AnyExpression(delegates.whereType<Expression>().toList());
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
    final inputExpression = _praseInputExpression(json);
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
  }

  Expression? _praseInputExpression(List json) {
    final input = json[2];
    if (input is List && input.length == 1) {
      return parser._parseOptionalPropertyOrExpression(input[0]);
    }
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
