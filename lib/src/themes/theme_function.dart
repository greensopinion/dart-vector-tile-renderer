import 'dart:ui';

import 'theme_function_model.dart';

abstract class ThemeFunction<T> {
  final Map<FunctionModel, _ZoomValue> _cache = {};

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
