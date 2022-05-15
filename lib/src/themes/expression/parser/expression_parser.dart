import 'dart:math';

import '../../../logger.dart';
import '../caching_expression.dart';
import '../expression.dart';
import '../literal_expression.dart';
import '../property_expression.dart';
import 'boolean_operator_expression_parser.dart';
import 'get_expression_parser.dart';
import 'interpolate_expression_parser.dart';
import 'math_expression_parser.dart';
import 'step_expression_parser.dart';
import 'string_expression_parser.dart';
import 'variable_expression_parser.dart';

// https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/

typedef ExpressionFunction = Expression Function();

class ExpressionParser {
  final Logger logger;
  Map<String, ExpressionComponentParser> _parserByOperator = {};
  ExpressionParser(this.logger) {
    _register(GetExpressionParser(this));
    _register(HasExpressionParser(this));
    _register(NotHasExpressionParser(this));
    _register(InExpressionParser(this));
    _register(NotInExpressionParser(this));
    _register(NotExpressionParser(this));
    _register(EqualsExpressionParser(this));
    _register(NotEqualsExpressionParser(this));
    _register(ComparisonExpressionParser(
        this, '<', (first, second) => first < second));
    _register(ComparisonExpressionParser(
        this, '>', (first, second) => first > second));
    _register(ComparisonExpressionParser(
        this, '<=', (first, second) => first <= second));
    _register(ComparisonExpressionParser(
        this, '>=', (first, second) => first >= second));
    _register(AllExpressionParser(this));
    _register(AnyExpressionParser(this));
    _register(InterpolateExpressionParser(this), caching: true);
    _register(StepExpressionParser(this));
    _register(CaseExpressionParser(this));
    _register(ToStringExpressionParser(this));
    _register(MatchExpressionParser(this));
    _register(GeometryTypeExpressionParser(this));
    _register(CoalesceExpressionParser(this));
    _register(NaryMathExpressionParser(this, '*', (a, b) => a * b));
    _register(NaryMathExpressionParser(this, '/', (a, b) => a / b));
    _register(NaryMathExpressionParser(this, '+', (a, b) => a + b));
    _register(NaryMathExpressionParser(this, '-', (a, b) => a - b));
    _register(NaryMathExpressionParser(this, '%', (a, b) => a % b));
    _register(NaryMathExpressionParser(this, '^', pow));
    final varParser = VarExpressionParser(this);
    _register(varParser);
    _register(LetExpressionParser(this, varParser));
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
          return wrapConstant(expression);
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
      } else {
        final property = json['property'];
        if (property is String) {
          return GetPropertyExpression(property);
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

  void _register(ExpressionComponentParser delegate, {bool caching = false}) {
    if (_parserByOperator.containsKey(delegate.operator)) {
      throw Exception('duplicate operator ${delegate.operator}');
    }
    _parserByOperator[delegate.operator] =
        caching ? _CacheParserWrapper(delegate) : delegate;
  }

  Expression? parseOptionalPropertyOrExpression(json) {
    if (json is String) {
      return parseOptional(['get', json]);
    }
    return parseOptional(json);
  }

  Expression parsePropertyOrExpression(json) {
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

abstract class ExpressionComponentParser {
  final ExpressionParser parser;
  final String operator;

  ExpressionComponentParser(this.parser, this.operator);

  bool matches(List<dynamic> json) {
    return json.length > 0 && json[0] == operator;
  }

  Expression? parse(List<dynamic> json);
}

class _CacheParserWrapper extends ExpressionComponentParser {
  final ExpressionComponentParser _delegate;

  _CacheParserWrapper(this._delegate)
      : super(_delegate.parser, _delegate.operator);

  @override
  bool matches(List<dynamic> json) => _delegate.matches(json);

  @override
  Expression? parse(List json) {
    final result = _delegate.parse(json);
    if (result != null) {
      return cache(result);
    }
    return null;
  }
}
