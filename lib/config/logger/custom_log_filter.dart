import 'package:logger/logger.dart';

class CustomLogFilter extends LogFilter {
  @override
  Level? get level => Level.trace;

  /// The minimal level allowed in production.
  static const Level minimalLevel = Level.info;

  @override
  bool shouldLog(LogEvent event) {
    bool shouldLog = false;

    if (event.level.index >= minimalLevel.index) {
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
