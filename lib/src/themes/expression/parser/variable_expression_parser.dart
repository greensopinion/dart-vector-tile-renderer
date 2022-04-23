import '../expression.dart';
import 'expression_parser.dart';

class LetExpressionParser extends ExpressionComponentParser {
  late final _VariableRegistry _registry;

  LetExpressionParser(
      ExpressionParser parser, VarExpressionParser varExpressionParser)
      : _registry = varExpressionParser._registry,
        super(parser, 'let');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length > 3 && json.length % 2 == 0;
  }

  Expression? parse(List<dynamic> json) {
    final output = json.last;
    final variableDefinitions = json.sublist(1, json.length - 1);

    for (int x = 0; x < variableDefinitions.length; x += 2) {
      final variableName = variableDefinitions[x];
      final variableExpression =
          parser.parseOptional(variableDefinitions[x + 1]);
      if (variableExpression == null) {
        return null;
      }
      if (variableName is String) {
        _registry.declare(variableName, variableExpression);
      } else {
        return null;
      }
    }
    return parser.parseOptional(output);
  }
}

class VarExpressionParser extends ExpressionComponentParser {
  final _VariableRegistry _registry = _VariableRegistry();

  VarExpressionParser(ExpressionParser parser) : super(parser, 'var');

  @override
  bool matches(List<dynamic> json) {
    return super.matches(json) && json.length == 2;
  }

  Expression? parse(List<dynamic> json) {
    final variableName = json.last;
    return _registry.reference(variableName);
  }
}

class _VariableRegistry {
  final _expressionByName = <String, Expression>{};

  void declare(String name, Expression value) {
    _expressionByName[name] = value;
  }

  Expression? reference(String name) => _expressionByName[name];
}
