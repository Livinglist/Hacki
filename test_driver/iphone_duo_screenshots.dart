import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// iOS integration_test screenshot callbacks run after the tests finish. A
// localhost handshake lets the app wait while the host captures and folds the
// real simulator; no viewport override or reconstructed image is involved.
Future<void> main() async {
  final Directory output = Directory(
    Platform.environment['DUO_CAPTURE_DIR'] ?? 'build/iphone-duo-simulator',
  );
  await output.create(recursive: true);
  final int port = int.parse(
    Platform.environment['DUO_CAPTURE_PORT'] ?? '8765',
  );
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    port,
  );

  Future<void> command(List<String> arguments) async {
    final ProcessResult result = await Process.run('bash', <String>[
      'scripts/iphone_duo_capture.sh',
      ...arguments,
    ]);
    await File('${output.path}/host-commands.log').writeAsString(
      '${arguments.join(' ')}\n${result.stdout}\n${result.stderr}\n',
      mode: FileMode.append,
    );
    if (result.exitCode != 0) {
      throw StateError('Native simulator command failed: ${result.stderr}');
    }
  }

  server.listen((HttpRequest request) async {
    try {
      if (request.method != 'POST' || request.uri.path != '/capture') {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      final Map<String, dynamic> data =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      final String name = data['name'] as String;
      const Set<String> names = <String>{
        '01-folded-feed',
        '02-unfolded-thread',
        '03-unfolded-rotated-thread',
        '04-refolded-thread',
        '05-refolded-feed',
      };
      if (!names.contains(name)) throw ArgumentError.value(name);
      await File(
        '${output.path}/$name-window.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      await command(<String>['capture', name]);
      final String? nextPose = data['nextPose'] as String?;
      if (nextPose != null) await command(<String>['pose', nextPose]);
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"ok":true}');
    } on Object catch (error, stackTrace) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('$error');
      await File(
        '${output.path}/host-errors.log',
      ).writeAsString('$error\n$stackTrace\n', mode: FileMode.append);
    } finally {
      await request.response.close();
    }
  });

  await integrationDriver(
    timeout: const Duration(minutes: 10),
    writeResponseOnFailure: true,
    responseDataCallback: (Map<String, dynamic>? data) => File(
      '${output.path}/integration-results.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data)),
  );
}
