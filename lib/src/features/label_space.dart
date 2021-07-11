import 'dart:ui';

class LabelSpace {
  final Rect space;
  final List<Rect> occupied = [];

  LabelSpace(this.space);

  bool canOccupy(Rect rect) =>
      space.containsCompletely(rect) &&
      !occupied.any((existing) => existing.overlaps(rect));

  void occupy(Rect box) {
    final boxWithMargin = Rect.fromLTRB(box.left - margin, box.top - margin,
        box.right + (2 * margin), box.bottom + (2 * margin));
    occupied.add(boxWithMargin);
  }
}

extension _RectExtension on Rect {
  bool containsCompletely(Rect other) =>
      this.contains(other.topLeft) && this.contains(other.bottomRight);
}

final margin = 2.0;
