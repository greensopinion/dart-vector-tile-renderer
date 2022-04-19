import 'expression.dart';

typedef BinaryOperation = num Function(num, num);

class NaryMathExpression extends Expression {
  final BinaryOperation _operation;
  final List<Expression> _operands;

  NaryMathExpression(String operationName, this._operation, this._operands)
      : super('(${_operands.map((e) => e.cacheKey).join(operationName)})');

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
  Set<String> properties() {
    final accumulator = <String>{};
    for (final expression in _operands) {
      accumulator.addAll(expression.properties());
    }
    return accumulator;
  }
}
