extension IntExtension on int {
  Iterable<int> to(int other, {bool inclusive = true}) => other > this
      ? <int>[for (int i = this; i < other; i++) i, if (inclusive) other]
      : <int>[for (int i = this; i > other; i--) i, if (inclusive) other];
}
