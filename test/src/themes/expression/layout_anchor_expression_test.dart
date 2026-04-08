import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/expression/literal_expression.dart';
import 'package:vector_tile_renderer/src/themes/expression/text_expression.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  EvaluationContext context() => EvaluationContext(
        () => {},
        TileFeatureType.point,
        const Logger.noop(),
        zoom: 1.0,
        zoomScaleFactor: 1.0,
        hasImage: (_) => false,
      );

  group('LayoutAnchorExpression', () {
    test('evaluates bottom string to LayoutAnchor.bottom', () {
      final expression =
          LayoutAnchorExpression(LiteralExpression('bottom'));
      expect(expression.evaluate(context()), equals(LayoutAnchor.bottom));
    });

    test('evaluates top string to LayoutAnchor.top', () {
      final expression =
          LayoutAnchorExpression(LiteralExpression('top'));
      expect(expression.evaluate(context()), equals(LayoutAnchor.top));
    });

    test('evaluates center string to LayoutAnchor.center', () {
      final expression =
          LayoutAnchorExpression(LiteralExpression('center'));
      expect(expression.evaluate(context()), equals(LayoutAnchor.center));
    });

    test('evaluates null to DEFAULT', () {
      final expression =
          LayoutAnchorExpression(LiteralExpression(null));
      expect(expression.evaluate(context()), equals(LayoutAnchor.DEFAULT));
    });

    test('evaluates unknown string to DEFAULT', () {
      final expression =
          LayoutAnchorExpression(LiteralExpression('left'));
      expect(expression.evaluate(context()), equals(LayoutAnchor.DEFAULT));
    });
  });
}
