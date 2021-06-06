import 'dart:ui';

import 'package:vector_tile_renderer/src/themes/color_parser.dart';

class FunctionModel<T> {
  final T? base;
  final List<FunctionStop<T>> stops;

  FunctionModel(this.base, this.stops);
}

class FunctionStop<T> {
  final double zoom;
  final T value;

  FunctionStop(this.zoom, this.value);
}

class DoubleFunctionModelFactory {
  FunctionModel<double>? create(json) {
    double? base = (json['base'] as num?)?.toDouble();
    final stops = json['stops'] as List<dynamic>?;
    if (stops == null) {
      if (base != null) {
        return FunctionModel<double>(base, []);
      }
      return null;
    }
    final modelStops = <FunctionStop<double>>[];
    for (final stop in stops) {
      final stopZoom = (stop[0] as num).toDouble();
      final stopValue = (stop[1] as num).toDouble();
      modelStops.add(FunctionStop<double>(stopZoom, stopValue));
    }
    return FunctionModel<double>(base, modelStops);
  }
}

class ColorFunctionModelFactory {
  FunctionModel<Color>? create(json) {
    Color? base = json['base'] is String
        ? ColorParser.toColor(json['base'] as String?)
        : null;
    final stops = json['stops'] as List<dynamic>?;
    if (stops == null) {
      if (base != null) {
        return FunctionModel<Color>(base, []);
      }
      return null;
    }
    final modelStops = <FunctionStop<Color>>[];
    for (final stop in stops) {
      final stopZoom = (stop[0] as num).toDouble();
      final stopValue = ColorParser.toColor(stop[1] as String);
      if (stopValue != null) {
        modelStops.add(FunctionStop<Color>(stopZoom, stopValue));
      }
    }
    return FunctionModel<Color>(base, modelStops);
  }
}
