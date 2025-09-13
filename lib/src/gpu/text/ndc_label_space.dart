import 'dart:ui';

class NdcLabelSpace {
  final Set<Rect> existing = {};
  
  bool tryOccupy(Rect space) {
    final currentExisting = existing.toSet();
    for(final rect in currentExisting) {
      if (rect.overlaps(space)) {
        return false;
      }
    }
    existing.add(space);
    return true;
  }
}