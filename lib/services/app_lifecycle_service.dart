import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hacki/extensions/extensions.dart';

class AppLifecycleService with WidgetsBindingObserver, Loggable {
  AppLifecycleService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();

  Stream<AppLifecycleState> get stream => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logDebug('app state changed to $state');
    _controller.add(state);
  }

  @override
  String get logIdentifier => 'AppLifecycleService';
}
