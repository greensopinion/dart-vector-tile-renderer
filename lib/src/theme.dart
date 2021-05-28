import 'dart:ui';

class ThemeElement {
  final Paint fillPaint;
  final Paint linePaint;

  ThemeElement({required this.fillPaint, required this.linePaint});
}

class Theme {
  final Map<String, ThemeElement> _nameToElement;
  Theme(this._nameToElement);

  ThemeElement? element({required String name}) => _nameToElement[name];
}
