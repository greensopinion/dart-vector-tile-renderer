import 'package:collection/collection.dart';

import 'expression.dart';

class CachingExpression<T> extends Expression<T> {
  final Expression _delegate;
  CachingExpression(this._delegate)
      : super(_delegate.cacheKey, _delegate.properties());

  _EntryCache<T> _cache = _EntryCache<T>(50);

  @override
  T? evaluate(EvaluationContext context) {
    final key = _createKey(context);
    _CacheEntry<T>? value = _cache.get(key);
    if (value == null) {
      value = _CacheEntry(_delegate.evaluate(context));
      _cache.put(key, value);
    }
    return value.value;
  }

  String _createKey(EvaluationContext context) => properties()
      .sorted()
      .map((e) => '$e:${context.getProperty(e)}')
      .join(',');
}

class _EntryCache<T> {
  final Map<String, _CacheEntry<T>> _entries = {};
  final int _maxSize;
  _EntryCache(this._maxSize);

  _CacheEntry<T>? get(String key) => _entries[key];

  put(String key, _CacheEntry<T> value) {
    _entries[key] = value;
    if (_entries.length > _maxSize) {
      _entries.remove(_entries.keys.last);
    }
  }
}

class _CacheEntry<T> {
  final T? value;

  _CacheEntry(this.value);
}
