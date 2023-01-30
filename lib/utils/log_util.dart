import 'dart:io';
import 'dart:typed_data';

import 'package:hacki/config/constants.dart';
import 'package:path_provider/path_provider.dart';

abstract class LogUtil {
  static Future<File> exportLog() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String logPath = '${tempDir.path}/${Constants.logFilename}';
    final String previousLogPath =
        '${tempDir.path}/${Constants.previousLogFileName}';
    final File currentSessionLog = File(logPath);
    final File previousSessionLog = File(previousLogPath);

    final Uint8List fileContent = await currentSessionLog.readAsBytes();
    await previousSessionLog.writeAsString(
      'Current session logs:',
    );
    return previousSessionLog.writeAsBytes(
      fileContent,
    );
  }
}
