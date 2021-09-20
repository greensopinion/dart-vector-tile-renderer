import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/themes/theme_function.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

void main() {
  ValueExpression<double> v(double value) => ValueExpression(value);
  Map<String, dynamic> withZoom(double zoom) => {'zoom': zoom};

  final definition = FunctionModel<double>(v(1.2), [
    FunctionStop<double>(v(14), v(1.09)),
    FunctionStop<double>(v(20), v(6.19)),
  ]);

  final function = DoubleThemeFunction();
  final epsilon = 0.006;
  test('provides null for zoom values less than the lowest stop', () {
    expect(function.exponential(definition, withZoom(12)), isNull);
    expect(function.exponential(definition, withZoom(13)), isNull);
    expect(function.exponential(definition, withZoom(13.9)), isNull);
  });

  test('produces an exponent based on stops', () {
    expect(
      function.exponential(definition, withZoom(14)),
      closeTo(1.09, epsilon),
    );

    expect(
      function.exponential(definition, withZoom(20)),
      closeTo(6.19, epsilon),
    );
  });

  test('produces an exponent with zoom greater than top stop', () {
    expect(
      function.exponential(definition, withZoom(100)),
      closeTo(6.19, epsilon),
    );
  });

  test('produces an exponent with zoom between stops', () {
    expect(
      function.exponential(definition, withZoom(15)),
      closeTo(1.46, epsilon),
    );

    expect(
      function.exponential(definition, withZoom(19)),
      closeTo(4.64, epsilon),
    );
  });
}
