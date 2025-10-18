import 'theme.dart';

/// Manages theme lifecycle and transformations
abstract class ThemeManager {
  /// Creates a filtered theme containing only the specified layer types
  Theme filterTheme(Theme theme, Set<ThemeLayerType> types);

  /// Creates a theme variant for symbols only
  Theme createSymbolTheme(Theme theme);

  /// Creates a theme variant excluding symbols
  Theme createNonSymbolTheme(Theme theme);

  /// Validates theme compatibility with tile sources
  bool validateThemeCompatibility(Theme theme, List<String> availableSources);
}

/// Default implementation of ThemeManager
class DefaultThemeManager implements ThemeManager {
  const DefaultThemeManager();
  @override
  Theme filterTheme(Theme theme, Set<ThemeLayerType> types) {
    return theme.copyWith(types: types);
  }

  @override
  Theme createSymbolTheme(Theme theme) {
    return theme.copyWith(
      id: '${theme.id}-symbols',
      types: {ThemeLayerType.symbol},
    );
  }

  @override
  Theme createNonSymbolTheme(Theme theme) {
    return theme.copyWith(
      types: ThemeLayerType.values
          .where((type) => type != ThemeLayerType.symbol)
          .toSet(),
    );
  }

  @override
  bool validateThemeCompatibility(Theme theme, List<String> availableSources) {
    final requiredSources = theme.tileSources.toSet();
    final availableSourcesSet = availableSources.toSet();
    return requiredSources
        .every((source) => availableSourcesSet.contains(source));
  }
}
