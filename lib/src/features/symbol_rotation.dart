import '../themes/expression/expression.dart';
import '../themes/style.dart';

extension SymbolRotation on SymbolLayout {
  RotationAlignment textRotationAlignment(EvaluationContext evaluationContext,
      {required LayoutPlacement layoutPlacement}) {
    var textRotationAlignment =
        text?.rotationAlignment?.evaluate(evaluationContext) ??
            RotationAlignment.auto;
    return _rotationAlignment(
        evaluationContext, textRotationAlignment, layoutPlacement);
  }

  RotationAlignment iconRotationAlignment(EvaluationContext evaluationContext,
      {required LayoutPlacement layoutPlacement}) {
    var iconRotationAlignment =
        icon?.rotationAlignment?.evaluate(evaluationContext) ??
            RotationAlignment.auto;
    return _rotationAlignment(
        evaluationContext, iconRotationAlignment, layoutPlacement);
  }

  RotationAlignment _rotationAlignment(EvaluationContext evaluationContext,
      RotationAlignment rotationAlignment, LayoutPlacement layoutPlacement) {
    if (rotationAlignment == RotationAlignment.auto) {
      final placement =
          this.placement.evaluate(evaluationContext) ?? layoutPlacement;
      if (placement == LayoutPlacement.point) {
        rotationAlignment = RotationAlignment.viewport;
      } else {
        rotationAlignment = RotationAlignment.map;
      }
    }
    return rotationAlignment;
  }
}
