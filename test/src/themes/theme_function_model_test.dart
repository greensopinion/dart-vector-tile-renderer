import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/theme_function.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

void main() {
  test('produces a color model', () {
    final definition = {
      "base": 1,
      "stops": [
        [9, "hsla(0, 3%, 85%, 0.84)"],
        [12, "hsla(35, 57%, 88%, 0.49)"]
      ]
    };
    final model = ColorFunctionModelFactory().create(definition);
    expect(model, isNotNull);
    expect(model!.base, isNull);
    expect(model.stops, hasLength(2));
    expect(model.stops[0].zoom, 9);
    expect(model.stops[1].zoom, 12);
  });
  test('produces a double model', () {
    final definition = {
      "base": 1.4,
      "stops": [
        [8, 1],
        [20, 2]
      ]
    };
    final model = DoubleFunctionModelFactory().create(definition);
    expect(model, isNotNull);
    expect(model!.base, 1.4);
    expect(model.stops, hasLength(2));
    expect(model.stops[0].zoom, 8);
    expect(model.stops[0].value, 1);
    expect(model.stops[1].zoom, 20);
    expect(model.stops[1].value, 2);
  });
}
