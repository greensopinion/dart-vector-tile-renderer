import 'expression.dart';

class ConditionOutputPair {
  final Expression condition;
  final Expression output;

  ConditionOutputPair(this.condition, this.output);

  String toCacheKey() => '${condition.cacheKey}:${output.cacheKey}';
}

class CaseExpression extends Expression {
  final List<ConditionOutputPair> cases;
  CaseExpression(this.cases)
      : super('case(${cases.map((e) => e.toCacheKey()).join(';')})');

  @override
  evaluate(EvaluationContext context) {
    for (final aCase in cases) {
      final condition = aCase.condition.evaluate(context);
      if (condition is bool && condition) {
        return aCase.output.evaluate(context);
      }
    }
    return null;
  }

  @override
  Set<String> properties() {
    final accumulator = <String>{};
    for (final aCase in cases) {
      accumulator.addAll(aCase.condition.properties());
      accumulator.addAll(aCase.output.properties());
    }
    return accumulator;
  }
}
