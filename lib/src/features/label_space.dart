import 'dart:ui';

class LabelSpace {
  List<Rect> occupied = [];

  bool isOccupied(Rect rect) =>
      occupied.any((existing) => existing.overlaps(rect));

  void occupy(Rect box) {
    final boxWithMargin = Rect.fromLTRB(box.left - margin, box.top - margin,
        box.right + (2 * margin), box.bottom + (2 * margin));
    occupied.add(boxWithMargin);
  }
}

final margin = 2.0;
