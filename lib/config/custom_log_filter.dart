import 'package:logger/logger.dart';

class CustomLogFilter extends LogFilter {
  @override
  // ignore: overridden_fields
  Level? level = Level.verbose;

  /// The minimal level allowed in production.
  static const Level _minimalLevel = Level.info;

  @override
  bool shouldLog(LogEvent event) {
    bool shouldLog = false;

    if (event.level.index >= _minimalLevel.index) {
      return true;
    }

    assert(
      () {
        if (event.level.index >= level!.index) {
          shouldLog = true;
        }
        return true;
      }(),
      '',
    );

    return shouldLog;
  }
}
