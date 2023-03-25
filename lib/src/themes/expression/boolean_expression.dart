import 'expression.dart';

class ToBooleanExpression extends Expression<bool> {
  final Expression _delegate;

  ToBooleanExpression(this._delegate)
      : super('toBoolean(${_delegate.cacheKey})', _delegate.properties());

  @override
  bool evaluate(EvaluationContext context) {
    final v = _delegate.evaluate(context);
    if (v == "" ||
        v == 0 ||
        v == "false" ||
        v == false ||
        v == null ||
        (v is num && v.isNaN)) {
      return false;
    }
    return true;
  }

  @override
  bool get isConstant => _delegate.isConstant;
}
