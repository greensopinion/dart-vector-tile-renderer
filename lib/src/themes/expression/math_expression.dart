import 'expression.dart';
import 'property_accumulator.dart';

typedef BinaryOperation = num Function(num, num);
typedef UnaryOperation = num Function(num);

class NaryMathExpression extends Expression {
  final BinaryOperation _operation;
  final List<Expression> _operands;

  NaryMathExpression(String operationName, this._operation, this._operands)
      : super('(${_operands.map((e) => e.cacheKey).join(operationName)})',
            _operands.joinProperties());

  @override
  evaluate(EvaluationContext context) {
    var previous = _operands.first.evaluate(context);
    for (var nextExpression in _operands.sublist(1)) {
      var next = nextExpression.evaluate(context);
      if (next is num && previous is num) {
        previous = _operation(previous, next);
      } else {
        return null;
      }
    }
    return previous;
  }

  @override
  bool get isConstant => !_operands.any((e) => !e.isConstant);
}

class UnaryMathExpression extends Expression {
  final UnaryOperation _operation;
  final Expression _operand;

  UnaryMathExpression(String operationName, this._operation, this._operand)
      : super('$operationName(${_operand.cacheKey})', _operand.properties());

  @override
  evaluate(EvaluationContext context) {
    final operand = _operand.evaluate(context);
    if (operand is num) {
      return _operation(operand);
    }
    return null;
  }

  @override
  bool get isConstant => _operand.isConstant;
}
