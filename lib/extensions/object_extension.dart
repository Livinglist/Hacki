import 'package:hacki/config/locator.dart';
import 'package:logger/logger.dart';

extension ObjectExtension on Object {
  void log({String identifier = ''}) {
    locator.get<Logger>().d('$identifier ${toString()}');
  }
}
