import 'dart:math';

extension ListExtension<T> on List<T> {
  T? get randomlyPicked {
    if (isEmpty) return null;
    final Random random = Random(DateTime.now().millisecondsSinceEpoch);
    final int luckyNumber = random.nextInt(length);
    return this[luckyNumber];
  }
}
