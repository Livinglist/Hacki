import 'dart:math';

import 'package:flutter/foundation.dart';

extension ListExtension<T> on List<T> {
  @visibleForTesting
  static Random Function() randomFactory = Random.secure;

  T? get randomlyPicked {
    if (isEmpty) return null;
    final Random random = randomFactory();
    final int luckyNumber = random.nextInt(length);
    return this[luckyNumber];
  }

  List<T> reversedIf({required bool condition}) =>
      condition ? List<T>.from(reversed) : this;
}
