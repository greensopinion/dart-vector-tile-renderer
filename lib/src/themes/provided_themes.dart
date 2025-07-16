import '../logger.dart';
import 'local/local_light_style.dart';
import 'theme.dart';
import 'theme_reader.dart';

class ProvidedThemes {
  ProvidedThemes._();

  static Theme lightTheme({Logger? logger}) =>
      ThemeReader(logger: logger).read(lightStyle());
}
