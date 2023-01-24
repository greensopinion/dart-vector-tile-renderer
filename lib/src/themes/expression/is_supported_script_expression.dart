import 'package:flutter/widgets.dart';

import 'expression.dart';

class IsSupportedScriptExpression extends Expression {
  final Expression _expression;

  IsSupportedScriptExpression(this._expression)
      : super('isSupportedScript(${_expression.cacheKey})', _expression.properties());

  @override
  evaluate(EvaluationContext context) {
    final operand = _expression.evaluate(context);
    if (operand is String) {
      // Most MapLibre/Mapbox renderers use SDF glyph rendering, which has
      // problems with scripts requiring complex text shaping (ex: Khmer,
      // Nepalese, Burmese, Devanagari, etc.) and, in some cases, lack RTL support.
      //
      // At the moment, known rendering frontends utilizing this library, such
      // as the flutter_map plugin, utilize more traditional font rendering
      // approaches, so we can assume that all characters are supported.
      //
      // More about complex scripts: https://en.wikipedia.org/wiki/Complex_text_layout
      //
      // Canonical implementations for SDF-based renderers:
      // JS: https://github.com/maplibre/maplibre-gl-js/blob/51054671229c68d798fa06a64968aa35688f6a0f/src/util/script_detection.ts#L319
      // C++: https://github.com/maplibre/maplibre-gl-native/blob/32ed70c95d734590b3e68cd4595a2806fd13c389/src/mbgl/util/i18n.cpp#L632
      return true;
    }
    context.logger.warn(() => 'IsSupportedScriptExpression expected string but got $operand');
    return null;
  }

  @override
  bool get isConstant => _expression.isConstant;
}