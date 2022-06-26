import 'dart:ui';

class RingNumberProvider<T> {
  RingNumberProvider(this._vals);

  final List<T> _vals;
  int _idx = 0;

  T get next {
    if (_idx >= _vals.length) {
      _idx = 0;
    }
    return _vals[_idx++];
  }
}

extension DashPath on Path {
  // convert a path into a dashed path with given intervals
  Path dashPath(RingNumberProvider<num> dashArray) {
    final Path dest = Path();
    for (final PathMetric metric in this.computeMetrics()) {
      double distance = .0;
      bool draw = true;
      while (distance < metric.length) {
        final num len = dashArray.next;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }

    return dest;
  }
}
