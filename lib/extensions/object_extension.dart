import 'dart:developer' as dev;

extension ObjectExtension on Object {
  void log({String identifier = ''}) {
    dev.log('$identifier ${toString()}', level: 2000);
  }
}
