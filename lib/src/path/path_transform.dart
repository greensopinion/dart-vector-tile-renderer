import 'dart:ui';

import 'ring_number_provider.dart';

extension DashPath on Path {
  // creates a new dashed path with the given intervals
  Path dashPath(RingNumberProvider dashArray) {
    final Path dest = Path();
    for (final PathMetric metric in computeMetrics()) {
      double distance = .0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }

    return dest;
  }
}
