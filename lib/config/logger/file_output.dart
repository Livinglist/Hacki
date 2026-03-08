import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

/// Writes the log output to a file.
/// Temporary solution to not being able to access
// ignore: comment_references
/// the original [FileOutput] from [Logger]
class CustomFileOutput extends LogOutput {
  CustomFileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  @override
  Future<void> init() async {
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
