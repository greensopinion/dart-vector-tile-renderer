import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../expression.dart';
import 'interpolation_expression.dart';

class LinearInterpolationExpression<T> extends InterpolationExpression<T> {
  LinearInterpolationExpression(
      Expression<double> input, List<FunctionStop<T>> stops)
      : super(input, stops);

  @override
  double getInterpolationFactor(
          double input, double lowerValue, double upperValue) =>
      exponentialInterpolation(input, 1, lowerValue, upperValue);
}
