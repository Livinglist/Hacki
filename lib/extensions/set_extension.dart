extension SetExtension<E> on Set<E> {
  void removeWhereType<T extends E>() {
    return removeWhere((E e) => e is T);
  }

  bool hasType<T extends E>() {
    return whereType<T>().isNotEmpty;
  }

  T singleWhereType<T extends E>() {
    return whereType<T>().single;
  }
}
