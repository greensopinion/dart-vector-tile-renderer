class LazyValue<T> {
  T? _memoized;

  T get(T Function() compute) {
    var v = _memoized;
    if (v == null) {
      v = compute();
      _memoized = v;
    }
    return v!;
  }
}
