import 'dart:ui';

class ThemeElement {
  final Paint paint;

  ThemeElement(this.paint);
}

class Theme {
  final Map<String, ThemeElement> _nameToElement;
  Theme(this._nameToElement);

  ThemeElement? element({required String name}) => _nameToElement[name];
}
