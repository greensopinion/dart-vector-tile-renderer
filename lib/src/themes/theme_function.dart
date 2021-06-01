import 'dart:math';

class ThemeFunction {
  double? exponential(json, double zoom) {
    final base = (json['base'] as num?)?.toDouble() ?? 1.0;
    double lowerStop = 0;
    double lowerStopZoom = -1;
    double upperStop = lowerStop;
    double upperStopZoom = lowerStopZoom;
    final stops = json['stops'] as List<dynamic>?;
    if (stops == null) {
      return null;
    }
    for (var stop in stops) {
      final stopZoom = (stop[0] as num).toDouble();
      final stopValue = (stop[1] as num).toDouble();
      if (stopZoom > zoom && lowerStopZoom == -1) {
        return null;
      }
      if (stopZoom <= zoom) {
        lowerStop = stopValue;
        lowerStopZoom = stopZoom;
        upperStop = lowerStop;
        upperStopZoom = lowerStopZoom;
      } else {
        upperStop = stopValue;
        upperStopZoom = stopZoom;
        break;
      }
    }
    double stopZoomDifference = upperStopZoom - lowerStopZoom;
    double effectiveStop = lowerStop;
    if (stopZoomDifference > 0) {
      double zoomOffset = (zoom - lowerStopZoom) / stopZoomDifference;
      double stopDifference = upperStop - lowerStop;
      effectiveStop = lowerStop + (stopDifference * zoomOffset);
    }
    return pow(base, effectiveStop).toDouble();
  }
}
