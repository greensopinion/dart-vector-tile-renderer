import 'package:flutter_gpu/gpu.dart';

class TextureProvider {
  final _loaded = <int, Texture>{};

  Texture? get(int id) => _loaded[id];

  void addLoaded(Texture texture, int key) {
    _loaded[key] = texture;
  }

  void unloadWhereNotFound(Set<int> neededKeys) {
    final keysToRemove =
        _loaded.keys.where((key) => !neededKeys.contains(key)).toList();
    for (final key in keysToRemove) {
      _loaded.remove(key);
    }
  }
}
