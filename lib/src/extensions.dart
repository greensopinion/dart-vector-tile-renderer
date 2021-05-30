extension IterableExtension<T> on Iterable<T> {
  T? firstOrNull() => isEmpty ? null : first;
}
