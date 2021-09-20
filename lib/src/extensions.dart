import 'dart:ui';

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNull() => isEmpty ? null : first;

  List<List<T>> chunk(int chunkSize) {
    final List<List<T>> chunks = [];
    final list = toList();

    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      );
      chunks.add(chunk);
    }

    return chunks;
  }
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
