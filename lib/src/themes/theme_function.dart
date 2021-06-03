import 'dart:math';
import 'dart:ui';

import 'theme_function_model.dart';

abstract class ThemeFunction<T> {
  T? exponential(FunctionModel<T> model, double zoom) {
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
    return interpolate(model.base, lower, upper!, zoom);
  }

  T? interpolate(T? base, FunctionStop lower, FunctionStop upper, double zoom);
}

class DoubleThemeFunction extends ThemeFunction<double> {
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

class ColorThemeFunction extends ThemeFunction<Color> {
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
