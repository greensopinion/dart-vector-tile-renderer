import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/cubic_bezier_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/exponential_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/linear_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class InterpolationParser<T> extends ExpressionParser<T> {
  @override
  Expression<T>? parse(data) {
    if (data is! List) {
      return null;
    }

    assert(
      T == double || T == Color,
      'Linear interpolation is only supported for double and color values!',
    );

    assert(
      data.length >= 5 && data.length.isOdd,
      'Interpolation expressions must have an odd amount >= 5 of fields: The '
      'string literal "interpolate", followed by the interpolation type, '
      'followed by a numeric input expression, followed by pairs of input and '
      'output values to be used for interpolation.\n'
      'See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#interpolate for more information.\n'
      'Failed parsing on expression $data',
    );

    switch (data[1][0]) {
      case 'linear':
        return _parseLinear(data);
      case 'exponential':
        return _parseExponential(data);
      case 'cubic-bezier':
        return _parseCubicBezier(data);
      default:
        return null;
    }
  }

  double _toDouble(dynamic d) => (d as num).toDouble();
  Expression<double> _parseInput(List data) => Parsers.parse<double>(data[2])!;
  List<FunctionStop<T>> _parseStops(List data) => data.skip(3).chunk(2).map(
        (chunk) {
          var stop = Parsers.parse<double>(chunk[0]);
          var output = Parsers.parse<T>(chunk[1]);
          return FunctionStop<T>(
            stop!,
            output!,
          );
        },
      ).toList();

  _parseLinear(List data) {
    final input = _parseInput(data);
    final stops = _parseStops(data);
    return LinearInterpolationExpression<T>(input, stops);
  }

  _parseExponential(List data) {
    assert(
      data[1].length == 2,
      'The interpolation type "expression" must be defined by a list of two '
      'values: The string literal "expression" and the numeric base.\n'
      'See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#interpolate for more information.\n'
      'Failed parsing on interpolation type ${data[1]}',
    );

    final base = _toDouble(data[1][1]);
    final input = _parseInput(data);
    final stops = _parseStops(data);

    return ExponentialInterpolationExpression<T>(base, input, stops);
  }

  _parseCubicBezier(List data) {
    assert(
      data[1].length == 5,
      'The interpolation type "cubic-bezier" must be defined by a list of five '
      'values: The string literal "cubic-bezier" followed by the x and y '
      'values of the first control point and lastly the x and y values of the '
      'second control point.\n'
      'See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#interpolate for more information.\n'
      'Failed parsing on interpolation type ${data[1]}',
    );

    final x1 = _toDouble(data[1][1]);
    final y1 = _toDouble(data[1][2]);
    final x2 = _toDouble(data[1][3]);
    final y2 = _toDouble(data[1][4]);

    final c1 = Vector2(x1, y1);
    final c2 = Vector2(x2, y2);

    final input = _parseInput(data);
    final stops = _parseStops(data);

    return CubicBezierInterpolationExpression<T>(c1, c2, input, stops);
  }
}
