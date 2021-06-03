import 'dart:math';
import 'dart:ui';

import 'theme_function_model.dart';

abstract class ThemeFunction<T> {
  Map<FunctionModel, _ZoomValue> _cache = {};

  T? exponential(FunctionModel<T> model, double zoom) {
    _ZoomValue? cached = _cache[model];
    if (cached != null && cached.isCloseTo(zoom)) {
      return cached.value;
    }
    FunctionStop? lower;
    FunctionStop? upper;
    for (var stop in model.stops) {
      if (stop.zoom > zoom && lower == null) {
        return null;
      }
      if (stop.zoom <= zoom) {
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
    cached = _ZoomValue(zoom, interpolate(model.base, lower, upper!, zoom));
    _cache[model] = cached;
    return cached.value;
  }

  T? interpolate(T? base, FunctionStop lower, FunctionStop upper, double zoom);
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
      double? base, FunctionStop lower, FunctionStop upper, double zoom) {
    if (base == null) {
      base = 1.0;
    }
    final factor = interpolationFactor(base, lower.zoom, upper.zoom, zoom);
    return (lower.value * (1 - factor)) + (upper.value * factor);
  }

  double interpolationFactor(
      double base, double lower, double upper, double input) {
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
      Color? base, FunctionStop lower, FunctionStop upper, double zoom) {
    final difference = lower.zoom - upper.zoom;
    if (difference < 1.0) {
      return lower.value;
    }
    final progress = zoom - lower.zoom;
    if (progress / difference < 0.5) {
      return lower.value;
    }
    return upper.value;
  }
}
