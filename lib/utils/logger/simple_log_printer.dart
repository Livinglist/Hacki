import 'dart:convert';

import 'package:logger/logger.dart';

/// Outputs simple log messages with no color:
/// ```
/// [E] Log message  ERROR: Error info
/// ```
class SimpleLogPrinter extends LogPrinter {
  static Map<Level, String> get levelPrefixes => SimplePrinter.levelPrefixes;

  static Map<Level, AnsiColor> get levelColors => SimplePrinter.levelColors;

  @override
  List<String> log(LogEvent event) {
    final String messageStr = _stringifyMessage(event.message);
    final String errorStr =
        event.error != null ? '  ERROR: ${event.error}' : '';
    final String timeStr = 'TIME: ${DateTimeFormat.dateAndTime(event.time)}';
    return <String>['${_labelFor(event.level)} $timeStr $messageStr$errorStr'];
  }

  String _labelFor(Level level) {
    final String prefix = levelPrefixes[level]!;

    return prefix;
  }

  String _stringifyMessage(dynamic message) {
    final dynamic finalMessage =
        message is Function ? (message as Function)() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      const JsonEncoder encoder = JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}
