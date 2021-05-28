extension ListExtension<T> on List<T> {
  List<T> sorted() {
    final copy = this.toList();
    copy.sort();
    return copy;
  }
}
