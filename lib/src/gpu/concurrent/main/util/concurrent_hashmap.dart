import 'dart:async';

class ConcurrentHashMap<K, V> {
  final Map<K, V> _map = <K, V>{};
  Future<void> _lock = Future.value();
  
  Future<T> _synchronized<T>(Future<T> Function() operation) async {
    final completer = Completer<void>();
    final currentLock = _lock;
    _lock = completer.future;
    
    await currentLock;
    try {
      return await operation();
    } finally {
      completer.complete();
    }
  }
  
  Future<V?> get(K key) => _synchronized(() async => _map[key]);
  
  Future<void> put(K key, V value) => _synchronized(() async {
    _map[key] = value;
  });
  
  Future<V?> remove(K key) => _synchronized(() async => _map.remove(key));
  
  Future<bool> containsKey(K key) => _synchronized(() async => _map.containsKey(key));
  
  Future<int> get length => _synchronized(() async => _map.length);
  
  Future<void> clear() => _synchronized(() async => _map.clear());
  
  Future<List<K>> get keys => _synchronized(() async => _map.keys.toList());
  
  Future<List<V>> get values => _synchronized(() async => _map.values.toList());
}