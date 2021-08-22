import 'dart:ui';

class LabelSpace {
  final Rect space;
  final List<_LabelRect> occupied = [];
  final Set<String> texts = Set();

  LabelSpace(this.space);

  bool canOccupy(String text, Rect rect) =>
      !texts.contains(text) &&
      space.containsCompletely(rect) &&
      !occupied.any((existing) => existing.space.overlaps(rect));

  void occupy(String text, Rect box) {
    final boxWithMargin = Rect.fromLTRB(box.left - margin, box.top - margin,
        box.right + (2 * margin), box.bottom + (2 * margin));
    occupied.add(_LabelRect(text, boxWithMargin));
    texts.add(text);
  }
}

extension _RectExtension on Rect {
  bool containsCompletely(Rect other) =>
      this.contains(other.topLeft) && this.contains(other.bottomRight);
}

final margin = 2.0;

class _LabelRect {
  final Rect space;
  final String text;
  _LabelRect(this.text, this.space);
}
