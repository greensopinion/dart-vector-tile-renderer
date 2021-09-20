import 'dart:math';
import 'dart:ui';

import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'theme_function_model.dart';

abstract class ThemeFunction<T> {
  Map<FunctionModel, _ZoomValue> _cache = {};

  T? exponential(FunctionModel<T> model, Map<String, dynamic> args) {
    final zoom = args['zoom'] as double;

    _ZoomValue? cached = _cache[model];
    if (cached != null && cached.isCloseTo(zoom)) {
      return cached.value;
    }
    FunctionStop<T>? lower;
    FunctionStop<T>? upper;
    for (var stop in model.stops) {
      final stopZoom = stop.zoom.evaluate(args)!;

      if (stopZoom > zoom && lower == null) {
        return null;
      }
      if (stopZoom <= zoom) {
        lower = stop;
        upper = stop;
      } else {
        upper = stop;
        break;
      }
    }
    if (lower == null) {
      return null;
    }
    cached = _ZoomValue(zoom, interpolate(model.base, lower, upper!, args));
    _cache[model] = cached;
    return cached.value;
  }

  T? interpolate(
    Expression<T>? base,
    FunctionStop<T> lower,
    FunctionStop<T> upper,
    Map<String, dynamic> args,
  );
}

class _ZoomValue<T> {
  final double zoom;
  final T? value;

  _ZoomValue(this.zoom, this.value);

  bool isCloseTo(double zoom) {
    if (zoom == this.zoom) {
      return true;
    }
    final difference = (zoom - this.zoom).abs();
    return difference < 0.02;
  }
}

DoubleThemeFunction _doubleFunction = DoubleThemeFunction._();

class DoubleThemeFunction extends ThemeFunction<double> {
  DoubleThemeFunction._();
  factory DoubleThemeFunction() => _doubleFunction;

  @override
  double? interpolate(
    Expression<double>? base,
    FunctionStop<double> lower,
    FunctionStop<double> upper,
    Map<String, dynamic> args,
  ) {
    if (base == null) {
      base = ValueExpression(1.0);
    }

    final zoom = args['zoom'];
    final factor = interpolationFactor(
      base.evaluate(args) ?? 1.0,
      lower.zoom.evaluate(args) ?? 1.0,
      upper.zoom.evaluate(args) ?? 1.0,
      zoom,
    );

    final lowerValue = lower.value.evaluate(args) ?? 0.0;
    final upperValue = upper.value.evaluate(args) ?? 0.0;

    return (lowerValue * (1 - factor)) + (upperValue * factor);
  }

  double interpolationFactor(
    double base,
    double lower,
    double upper,
    double input,
  ) {
    final difference = upper - lower;
    if (difference <= 1.0) {
      return 0;
    }
    final progress = input - lower;
    if (base <= 1.05 && base >= 0.95) {
      return progress / difference;
    }
    return (pow(base, progress) - 1) / (pow(base, difference) - 1);
  }
}

ColorThemeFunction _colorFunction = ColorThemeFunction._();

class ColorThemeFunction extends ThemeFunction<Color> {
  ColorThemeFunction._();
  factory ColorThemeFunction() => _colorFunction;

  @override
  Color? interpolate(
    Expression<Color>? base,
    FunctionStop<Color> lower,
    FunctionStop<Color> upper,
    Map<String, dynamic> args,
  ) {
    final zoom = args['zoom'] as double;

    final lowerZoom = lower.zoom.evaluate(args)!;
    final upperZoom = upper.zoom.evaluate(args)!;

    final difference = lowerZoom - upperZoom;
    if (difference < 1.0) {
      return lower.value.evaluate(args);
    }
    final progress = zoom - lowerZoom;
    if (progress / difference < 0.5) {
      return lower.value.evaluate(args);
    }
    return upper.value.evaluate(args);
  }
}
