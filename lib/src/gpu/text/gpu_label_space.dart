import 'dart:ui';

class GpuLabelSpace {
  final Map<Rect, void Function()> existing = {};
  
  void occupy(Rect space, void Function() onRemoved) {
    final currentExisting = existing.keys.toSet();
    for(final rect in currentExisting) {
      if (rect.overlaps(space)) {
        existing[rect]?.call();
        existing.remove(rect);
      }
    }
    existing[space] = onRemoved;
  }
}