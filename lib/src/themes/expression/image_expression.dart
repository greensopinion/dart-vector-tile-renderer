import 'expression.dart';

class ImageExpression extends Expression<String> {
  final Expression delegate;

  ImageExpression(this.delegate)
      : super('image(${delegate.cacheKey})', delegate.properties());

  @override
  String? evaluate(EvaluationContext context) {
    final value = delegate.evaluate(context);
    if (value is String && context.hasImage(value)) {
      return value;
    }
    return null;
  }

  @override
  bool get isConstant => delegate.isConstant;
}
