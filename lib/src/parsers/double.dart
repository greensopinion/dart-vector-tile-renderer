import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/function_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/themes/theme_function.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import 'interpolation.dart';
import 'parser.dart';

class DoubleParser extends Parser<double> {
  @override
  Expression<double>? parseSpecial(data) {
    if (data is num) {
      return ValueExpression(data.toDouble());
    }

    if (data is String) {
      final parsed = double.tryParse(data);
      return parsed == null ? null : ValueExpression(parsed);
    }

    if (data is List) {
      switch (data[0]) {
        case 'interpolate':
          return InterpolationParser<double>().parseSpecial(data);
        default:
          return null;
      }
    }

    if (data is Map) {
      final model = DoubleFunctionModelFactory().create(data);
      if (model != null) {
        return FunctionExpression(
          (args) => DoubleThemeFunction().exponential(model, args),
        );
      }
    }
  }
}
