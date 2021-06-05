import 'dart:ui';

class LabelSpace {
  List<Rect> occupied = [];

  bool isOccupied(Rect rect) =>
      occupied.any((existing) => existing.overlaps(rect));

  void occupy(Rect box) {
    occupied.add(box);
  }
}
