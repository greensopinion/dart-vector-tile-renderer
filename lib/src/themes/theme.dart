import '../context.dart';

class Theme {
  final List<ThemeLayer> layers;
  Theme(this.layers);
}

abstract class ThemeLayer {
  final String id;
  ThemeLayer(this.id);

  void render(Context context);
}
