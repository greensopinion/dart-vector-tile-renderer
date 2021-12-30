import 'package:vector_tile_renderer/src/themes/expression/property_expression.dart';

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
    _register(_InExpressionParser(this));
    _register(_NotInExpressionParser(this));
    _register(_NotExpressionParser(this));
    _register(_EqualsExpressionParser(this));
    _register(_NotEqualsExpressionParser(this));
  }

  Expression parse(dynamic json) {
    final expression = parseOptional(json);
    if (expression == null) {
      logger.warn(() => 'Unsupported expression syntax: $json');
      return UnsupportedExpression(json);
    }
    return expression;
  }

  Expression? parseOptional(dynamic json) {
    if (json is String || json is num || json is bool || json == null) {
      return LiteralExpression(json);
    }
    if (json is List && json.length > 1) {
      final operator = json[0];
      final delegate = _parserByOperator[operator];
      if (delegate != null && delegate.matches(json)) {
        final expression = delegate.parse(json);
        if (expression != null) {
          return expression;
        }
      }
    }
  }

  void _register(_ExpressionParser delegate) {
    if (_parserByOperator.containsKey(delegate.operator)) {
      throw Exception('duplicate operator ${delegate.operator}');
    }
    _parserByOperator[delegate.operator] = delegate;
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
    Expression? second;
    if (json[1] is String) {
      second = parser.parseOptional(['get', json[1]]);
    } else {
      second = parser.parseOptional(json[1]);
    }
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
    Expression? first;
    if (firstOperand is String) {
      first = parser.parseOptional(['get', firstOperand]);
    } else {
      first = parser.parseOptional(firstOperand);
    }
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
