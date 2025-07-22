import 'package:vector_tile_renderer/src/themes/light_theme.dart';

import '../logger.dart';
import 'theme.dart';
import 'theme_reader.dart';

class ProvidedThemes {
  ProvidedThemes._();

  static Theme lightTheme({Logger? logger}) =>
      ThemeReader(logger: logger).read(lightThemeData());
}
