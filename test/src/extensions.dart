extension ListExtension<T> on List<T> {
  List<T> sorted() {
    final copy = toList();
    copy.sort();
    return copy;
  }
}
