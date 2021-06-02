import 'dart:math';
import 'dart:ui';

import 'theme_function_model.dart';

abstract class ThemeFunction<T> {
  T? exponential(FunctionModel<T> model, double zoom) {
    T? lowerStop;
    double lowerStopZoom = -1;
    T? upperStop;
    double upperStopZoom = lowerStopZoom;
    for (var stop in model.stops) {
      if (stop.zoom > zoom && lowerStop == null) {
        return null;
      }
      if (stop.zoom <= zoom) {
        lowerStop = stop.value;
        lowerStopZoom = stop.zoom;
        upperStop = lowerStop;
        upperStopZoom = lowerStopZoom;
      } else {
        upperStop = stop.value;
        upperStopZoom = stop.zoom;
        break;
      }
    }
    double stopZoomDifference = upperStopZoom - lowerStopZoom;
    T? effectiveStop = lowerStop;
    if (stopZoomDifference > 0) {
      double differencePercentage = (zoom - lowerStopZoom) / stopZoomDifference;
      effectiveStop =
          applyDifference(lowerStop, upperStop, differencePercentage);
    }
    return applyFunction(model.base, effectiveStop);
  }

  T? applyFunction(T? base, T? effectiveStop);
  T? applyDifference(T? lower, T? upper, double offsetPercentage);
}

class DoubleThemeFunction extends ThemeFunction<double> {
  @override
  double? applyFunction(double? base, double? effectiveStop) {
    if (base != null && effectiveStop != null) {
      return pow(base, effectiveStop).toDouble();
    }
    return null;
  }

  @override
  double? applyDifference(
      double? lower, double? upper, double offsetPercentage) {
    if (lower != null && upper != null) {
      double stopDifference = upper - lower;
      return lower + (stopDifference * offsetPercentage);
    }
    return lower;
  }
}

class ColorThemeFunction extends ThemeFunction<Color> {
  @override
  Color? applyDifference(Color? lower, Color? upper, double offsetPercentage) {
    return lower;
  }

  @override
  Color? applyFunction(Color? base, Color? effectiveStop) {
    return effectiveStop;
  }
}
