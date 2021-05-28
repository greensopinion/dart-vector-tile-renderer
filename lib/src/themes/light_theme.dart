import 'dart:ui';

import '../theme.dart';

final _waterColour = Color.fromARGB(255, 0xad, 0xcd, 0xeb);

class LightTheme extends Theme {
  LightTheme()
      : super({
          "water": ThemeElement(
              fillPaint: Paint()
                ..style = PaintingStyle.fill
                ..color = _waterColour
                ..strokeWidth = 1.0,
              linePaint: Paint()
                ..style = PaintingStyle.stroke
                ..color = _waterColour
                ..strokeWidth = 1.0),
          "waterway": ThemeElement(
              fillPaint: Paint()
                ..style = PaintingStyle.fill
                ..color = _waterColour
                ..strokeWidth = 1.0,
              linePaint: Paint()
                ..style = PaintingStyle.stroke
                ..color = _waterColour
                ..strokeWidth = 1.0)
        });
}
