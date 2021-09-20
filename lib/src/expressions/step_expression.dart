import 'expression.dart';

class Step<T> {
  final num step;
  final Expression<T>? value;

  Step(this.step, this.value);
}

class StepExpression<T> extends Expression<T> {
  final Expression<double> _input;
  final Expression<T> _base;
  final Iterable<Step<T>> _steps;

  StepExpression(this._input, this._base, this._steps)
      : assert(_steps.isNotEmpty);

  @override
  T? evaluate(Map<String, dynamic> args) {
    final input = _input.evaluate(args)!;

    if (input < _steps.first.step) {
      return _base.evaluate(args);
    }

    final lastLessThanStop = _steps.lastWhere(
      (stop) => stop.step < input,
    );

    return lastLessThanStop.value?.evaluate(args);
  }
}
