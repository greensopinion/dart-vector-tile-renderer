import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/theme_function.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

void main() {
  final definition = FunctionModel<double>(
      1.2, [FunctionStop<double>(14, 0.5), FunctionStop<double>(20, 10)]);

  final function = DoubleThemeFunction();
  final epsilon = 0.006;
  test('provides null for zoom values less than the lowest stop', () {
    expect(function.exponential(definition, 12), isNull);
    expect(function.exponential(definition, 13), isNull);
    expect(function.exponential(definition, 13.9), isNull);
  });

  test('produces an exponent based on stops', () {
    expect(function.exponential(definition, 14), closeTo(1.09, epsilon));
    expect(function.exponential(definition, 20), closeTo(6.19, epsilon));
  });
  test('produces an exponent with zoom greater than top stop', () {
    expect(function.exponential(definition, 100), closeTo(6.19, epsilon));
  });
  test('produces null with zoom less than bottom stop', () {
    expect(function.exponential(definition, 0), isNull);
  });
  test('produces an exponent with zoom between stops', () {
    expect(function.exponential(definition, 15), closeTo(1.46, epsilon));
    expect(function.exponential(definition, 19), closeTo(4.64, epsilon));
  });
}
