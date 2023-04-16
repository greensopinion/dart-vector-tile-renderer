import 'dart:ui';

abstract class SymbolIcon {
  /// indicates whether the icon overlaps text
  bool get overlapsText;

  /// returns the size and offset of the rendered symbol
  Rect? render(Offset offset, {required Size contentSize});
}
