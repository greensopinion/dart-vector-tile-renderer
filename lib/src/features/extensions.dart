import 'dart:ui';

import '../context.dart';
import '../themes/style.dart';

extension ImageContextExtension on Context {
  bool hasImage(String imageName) =>
      tileSource.spriteIndex?.spriteByName[imageName] != null;
}

extension LayoutAnchorExtension on LayoutAnchor {
  Offset offset(Size size) {
    switch (this) {
      case LayoutAnchor.center:
        return Offset(-size.width / 2, -size.height / 2);
      case LayoutAnchor.top:
        return Offset(-size.width / 2, 0);
    }
    throw 'Not implemented: $name';
  }
}
