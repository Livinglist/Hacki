import 'dart:math';

extension ListExtension<T> on List<T> {
  T? pickRandomly() {
    if (isEmpty) return null;
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final luckyNumber = random.nextInt(length);
    return this[luckyNumber];
  }
}
