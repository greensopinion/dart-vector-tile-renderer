import 'dart:ui';

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

extension PaintExtension on Paint {
  Paint copy() => Paint()
    ..blendMode = blendMode
    ..color = color
    ..colorFilter = colorFilter
    ..filterQuality = filterQuality
    ..imageFilter = imageFilter
    ..invertColors = invertColors
    ..isAntiAlias = isAntiAlias
    ..maskFilter = maskFilter
    ..shader = shader
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeMiterLimit = strokeMiterLimit
    ..strokeWidth = strokeWidth
    ..style = style;
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
