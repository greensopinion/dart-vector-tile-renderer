import 'package:flutter_gpu/gpu.dart';

class TextureProvider {
  final _loaded = <int, Texture>{};

  Texture? get(int id) =>
      _loaded[id];

  void addLoaded(Texture texture, int key) {
    _loaded[key] = texture;
  }

  void unload(int key) {
    _loaded.remove(key);
  }
}