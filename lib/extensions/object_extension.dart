import 'package:hacki/config/locator.dart';
import 'package:logger/logger.dart';

extension ObjectExtension on Object {
  void log({String identifier = ''}) {
    locator.get<Logger>().d('$identifier ${toString()}');
  }

  void logInfo({String identifier = ''}) {
    locator.get<Logger>().i('$identifier ${toString()}');
  }

  void logError({
    String identifier = '',
    StackTrace? stackTrace,
  }) {
    locator.get<Logger>().e(identifier, this, stackTrace ?? StackTrace.current);
  }
}
