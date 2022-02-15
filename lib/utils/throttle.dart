import 'dart:async';

import 'package:flutter/foundation.dart';

class Throttle {
  Throttle({
    required this.delay,
  });

  final Duration delay;
  Timer? _timer;
  bool _canInvoke = true;

  void run(VoidCallback action) {
    if (_canInvoke) {
      action();
      _canInvoke = false;
      _timer = Timer(delay, () {
        _canInvoke = true;
      });
    }
  }

  void dispose() => _timer?.cancel();
}
