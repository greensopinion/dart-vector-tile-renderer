import 'package:collection/collection.dart';
import 'literal_expression.dart';

import 'expression.dart';

Expression<T> wrapConstant<T>(Expression<T> delegate) => delegate.isConstant &&
        !(delegate is LiteralExpression) &&
        !(delegate is _ConstantExpression)
    ? _ConstantExpression<T>(delegate)
    : delegate;

Expression<T> cache<T>(Expression<T> delegate) => delegate.isConstant
    ? _ConstantExpression<T>(delegate)
    : _CachingExpression<T>(delegate);

class _CachingExpression<T> extends Expression<T> {
  final Expression _delegate;
  final List<String> _propertyKeys;
  _CachingExpression(this._delegate)
      : _propertyKeys =
            List.from([..._delegate.properties()].sorted(), growable: false),
        super(_delegate.cacheKey, _delegate.properties());

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

  _CacheKey _createKey(EvaluationContext context) {
    final values = _propertyKeys
        .map((e) => context.getProperty(e))
        .toList(growable: false);

    return _CacheKey(values);
  }

  @override
  bool get isConstant => _delegate.isConstant;
}

class _ConstantExpression<T> extends Expression<T> {
  final Expression _delegate;
  _CacheEntry<T>? _constantValue;

  _ConstantExpression(this._delegate)
      : super(_delegate.cacheKey, _delegate.properties()) {
    assert(_delegate.isConstant);
  }

  @override
  T? evaluate(EvaluationContext context) {
    if (_constantValue == null) {
      _constantValue = _CacheEntry(_delegate.evaluate(context));
    }
    return _constantValue!.value;
  }

  @override
  bool get isConstant => true;
}

class _EntryCache<T> {
  final Map<_CacheKey, _CacheEntry<T>> _entries = {};
  final int _maxSize;
  _EntryCache(this._maxSize);

  _CacheEntry<T>? get(_CacheKey key) => _entries[key];

  put(_CacheKey key, _CacheEntry<T> value) {
    _entries[key] = value;
    if (_entries.length > _maxSize) {
      _entries.remove(_entries.keys.first);
    }
  }
}

class _CacheEntry<T> {
  final T? value;

  _CacheEntry(this.value);
}

final _equality = ListEquality();

class _CacheKey {
  final List _values;
  final int _hashCode;

  _CacheKey(this._values) : _hashCode = _equality.hash(_values);

  bool operator ==(other) =>
      other is _CacheKey &&
      other._hashCode == _hashCode &&
      _equality.equals(other._values, _values);

  @override
  int get hashCode => _hashCode;
}
