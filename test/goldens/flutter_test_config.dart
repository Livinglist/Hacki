import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/extensions/list_extension.dart';

/// Strict comparison is intentional. The canonical renderer is Linux, using the
/// pinned Flutter submodule; macOS unit jobs exclude the golden tag.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  ListExtension.randomFactory = () => Random(3);
  final List<dynamic> manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final Map<String, dynamic> font
      in manifest.cast<Map<String, dynamic>>()) {
    final FontLoader loader = FontLoader(font['family'] as String);
    for (final Map<String, dynamic> entry
        in (font['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(entry['asset'] as String));
    }
    await loader.load();
  }
  await testMain();
}
