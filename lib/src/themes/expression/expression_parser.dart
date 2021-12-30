import 'package:vector_tile_renderer/src/themes/expression/property_expression.dart';

import 'expression.dart';
import 'literal_expression.dart';

// https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/

class ExpressionParser {
  Map<String, _ExpressionParser> _parserByOperator = {};
  ExpressionParser() {
    _register(_GetExpressionParser());
    _register(_HasExpressionParser());
    _register(_NotExpressionParser());
  }

  Expression parse(dynamic json) {
    if (json is String || json is num || json is bool || json == null) {
      return LiteralExpression(json);
    }
    if (json is List && json.length > 1) {
      final operator = json[0];
      final delegate = _parserByOperator[operator];
      if (delegate != null && delegate.matches(json)) {
        return delegate.parse(json) ?? UnsupportedExpression(json);
      }
    }
    return UnsupportedExpression(json);
  }

  void _register(_ExpressionParser delegate) {
    if (_parserByOperator.containsKey(delegate.operator)) {
      throw Exception('duplicate operator ${delegate.operator}');
    }
    _parserByOperator[delegate.operator] = delegate;
  }
}

abstract class _ExpressionParser {
  final String operator;

  _ExpressionParser(this.operator);

  bool matches(List<dynamic> json) {
    return json.length > 0 && json[0] == operator;
  }

  Expression? parse(List<dynamic> json);
}

class _GetExpressionParser extends _ExpressionParser {
  _GetExpressionParser() : super('get');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    return GetPropertyExpression(json[1]);
  }
}

class _HasExpressionParser extends _ExpressionParser {
  _HasExpressionParser() : super('has');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = _GetExpressionParser().parse(json);
    if (getExpression != null) {
      return NotNullExpression(getExpression);
    }
  }
}

class _NotExpressionParser extends _ExpressionParser {
  _NotExpressionParser() : super('!');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  Expression? parse(List<dynamic> json) {
    final getExpression = _GetExpressionParser().parse(json[1]);
    if (getExpression != null) {
      return NotExpression(getExpression);
    }
  }
}
