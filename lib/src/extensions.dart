import 'dart:ui';

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

extension PaintExtension on Paint {
  Paint copy() => Paint()
    ..blendMode = this.blendMode
    ..color = this.color
    ..colorFilter = this.colorFilter
    ..filterQuality = this.filterQuality
    ..imageFilter = this.imageFilter
    ..invertColors = this.invertColors
    ..isAntiAlias = this.isAntiAlias
    ..maskFilter = this.maskFilter
    ..shader = this.shader
    ..strokeCap = this.strokeCap
    ..strokeJoin = this.strokeJoin
    ..strokeMiterLimit = this.strokeMiterLimit
    ..strokeWidth = this.strokeWidth
    ..style = this.style;
}

extension StringSetsExtension on Iterable<Set<String>> {
  Set<String> flatSet() {
    final values = <String>{};
    for (final set in this) {
      values.addAll(set);
    }
    return values;
  }
}
