import '../case_expression.dart';
import '../comparison_expression.dart';
import '../expression.dart';
import '../literal_expression.dart';
import 'expression_parser.dart';

class HasExpressionParser extends ExpressionComponentParser {
  HasExpressionParser(ExpressionParser parser) : super(parser, 'has');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2 && json[1] is String;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      return NotNullExpression(getExpression);
    }
    return null;
  }
}

class NotHasExpressionParser extends ExpressionComponentParser {
  NotHasExpressionParser(ExpressionParser parser) : super(parser, '!has');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 2 && json[1] is String;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      return NotExpression(NotNullExpression(getExpression));
    }
    return null;
  }
}

class InExpressionParser extends ExpressionComponentParser {
  InExpressionParser(ExpressionParser parser) : super(parser, 'in');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 3 && json[1] is String;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      final values = json.sublist(2);
      return InExpression(getExpression, values);
    }
    return null;
  }
}

class NotInExpressionParser extends ExpressionComponentParser {
  NotInExpressionParser(ExpressionParser parser) : super(parser, '!in');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length >= 3 && json[1] is String;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final getExpression = parser.parseOptional(['get', json[1]]);
    if (getExpression != null) {
      final values = json.sublist(2);
      return NotExpression(InExpression(getExpression, values));
    }
    return null;
  }
}

class NotExpressionParser extends ExpressionComponentParser {
  NotExpressionParser(ExpressionParser parser) : super(parser, '!');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  @override
  Expression? parse(List<dynamic> json) {
    Expression? second = parser.parseOptionalPropertyOrExpression(json[1]);
    if (second != null) {
      return NotExpression(second);
    }
    return null;
  }
}

class EqualsExpressionParser extends ExpressionComponentParser {
  EqualsExpressionParser(ExpressionParser parser) : super(parser, '==');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final firstOperand = json[1];
    final secondOperand = json[2];
    Expression? first = parser.parseOptionalPropertyOrExpression(firstOperand);
    Expression? second = parser.parseOptional(secondOperand);
    if (first != null && second != null) {
      return EqualsExpression(first, second);
    }
    return null;
  }
}

class NotEqualsExpressionParser extends ExpressionComponentParser {
  NotEqualsExpressionParser(ExpressionParser parser) : super(parser, '!=');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final delegate = parser.parseOptional(['==', json[1], json[2]]);
    if (delegate != null) {
      return NotExpression(delegate);
    }
    return null;
  }
}

class ComparisonExpressionParser extends ExpressionComponentParser {
  final bool Function(num, num) _comparison;

  ComparisonExpressionParser(
      ExpressionParser parser, String operator, this._comparison)
      : super(parser, operator);

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 3;
  }

  @override
  Expression? parse(List<dynamic> json) {
    final firstOperand = json[1];
    final secondOperand = json[2];
    final first = parser.parseOptionalPropertyOrExpression(firstOperand);
    final second = parser.parseOptional(secondOperand);
    if (first != null && second != null) {
      return ComparisonExpression(_comparison, operator, first, second);
    }
    return null;
  }
}

class AllExpressionParser extends ExpressionComponentParser {
  AllExpressionParser(ExpressionParser parser) : super(parser, 'all');

  @override
  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AllExpression(
        delegates.whereType<Expression>().toList(growable: false));
  }
}

class AnyExpressionParser extends ExpressionComponentParser {
  AnyExpressionParser(ExpressionParser parser) : super(parser, 'any');

  @override
  Expression? parse(List<dynamic> json) {
    final delegates = json.sublist(1).map((e) => parser.parseOptional(e));
    if (delegates.any((e) => e == null)) {
      return null;
    }
    return AnyExpression(
        delegates.whereType<Expression>().toList(growable: false));
  }
}

class MatchExpressionParser extends ExpressionComponentParser {
  MatchExpressionParser(ExpressionParser parser) : super(parser, 'match');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 3;
  }

  @override
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

class CaseExpressionParser extends ExpressionComponentParser {
  CaseExpressionParser(ExpressionParser parser) : super(parser, 'case');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 3 && json.length % 2 == 0;
  }

  @override
  Expression? parse(List json) {
    // ['case',condition,output,condition2,output2,fallbackOutput]
    var params = json.sublist(1, json.length - 1);
    var fallbackOutput = parser.parseOptional(json.last);
    if (fallbackOutput == null) {
      return null;
    }
    final cases = <ConditionOutputPair>[];
    for (int x = 0; x < params.length; x += 2) {
      final condition = parser.parseOptional(params[x]);
      final output = parser.parseOptional(params[x + 1]);

      if (condition == null || output == null) {
        return null;
      }
      cases.add(ConditionOutputPair(condition, output));
    }
    cases.add(ConditionOutputPair(LiteralExpression(true), fallbackOutput));
    return CaseExpression(cases);
  }
}
