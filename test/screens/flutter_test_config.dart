import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  final GoldenFileComparator comparator = goldenFileComparator;
  if (!Platform.isMacOS && comparator is LocalFileComparator) {
    goldenFileComparator = _SkippedGoldenFileComparator(
      comparator.basedir.resolve('test.dart'),
    );
  }

  return testMain();
}

/// Loads the fonts bundled with the app, including the Material icon font,
/// so goldens show real text and icons instead of placeholder boxes.
Future<void> _loadAppFonts() async {
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
}

/// Goldens are generated on macOS. Glyphs rasterize differently on other
/// platforms, so the pixel comparison is skipped there; the widgets are
/// still built and laid out.
class _SkippedGoldenFileComparator extends LocalFileComparator {
  _SkippedGoldenFileComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;
}
