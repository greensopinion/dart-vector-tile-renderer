import 'dart:ui';

abstract class SymbolIcon {
  RenderedIcon? render(Offset offset,
      {required Size contentSize, required bool withRotation});
}

class RenderedIcon {
  final bool overlapsText;
  final Rect area;
  final Rect contentArea;

  RenderedIcon(
      {required this.overlapsText,
      required this.area,
      required this.contentArea});
}
