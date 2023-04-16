import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'symbol_icon.dart';
import 'icon_renderer.dart';

extension SymbolLayoutExtension on SymbolLayout {
  SymbolIcon? getIcon(Context context, EvaluationContext evaluationContext) {
    final iconName = icon?.icon.evaluate(evaluationContext);
    SymbolIcon? iconRenderer;
    if (iconName != null) {
      final sprite = context.tileSource.spriteIndex?.spriteByName[iconName];
      final atlas = context.tileSource.spriteAtlas;
      if (sprite != null && atlas != null) {
        final size = icon?.size?.evaluate(evaluationContext) ?? 1.0;
        iconRenderer =
            IconRenderer(context, sprite: sprite, atlas: atlas, size: size);
      } else {
        context.logger.warn(() => 'missing sprite: $icon');
      }
    }
    return iconRenderer;
  }
}
