import 'package:bezier/bezier.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../expression.dart';
import 'interpolation_expression.dart';

class CubicBezierInterpolationExpression<T> extends InterpolationExpression<T> {
  final Vector2 _c1;
  final Vector2 _c2;

  CubicBezierInterpolationExpression(
    this._c1,
    this._c2,
    Expression<double> input,
    List<FunctionStop<T>> stops,
  ) : super(input, stops);

  @override
  double getInterpolationFactor(
      double input, double lowerValue, double upperValue) {
    final t = exponentialInterpolation(input, 1, lowerValue, upperValue);
    final curve = CubicBezier([Vector2(0, 0), _c1, _c2, Vector2(1, 1)]);
    return curve.pointAt(t).y;
  }
}
