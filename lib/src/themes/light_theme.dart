import 'dart:ui';

import '../theme.dart';

class LightTheme extends Theme {
  LightTheme()
      : super({
          "water": ThemeElement(Paint()
            ..style = PaintingStyle.fill
            ..color = Color.fromARGB(255, 0xad, 0xcd, 0xeb)
            ..strokeWidth = 1.0)
        });
}
