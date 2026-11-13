import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// How far a color channel of a pixel may be from the golden before the
/// pixel counts as different. Different macOS versions rasterize curved
/// glyph edges slightly differently, which shifts edge pixels by a small
/// amount; a real change such as a different icon shifts them by far more.
const int _channelTolerance = 64;

/// The share of pixels allowed to differ by more than [_channelTolerance].
const double _maxDifferingPixelRatio = 0.0003;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    final Uri testFile = comparator.basedir.resolve('test.dart');
    goldenFileComparator = Platform.isMacOS
        ? _FuzzyGoldenFileComparator(testFile)
        : _SkippedGoldenFileComparator(testFile);
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

/// Passes when the image matches the golden apart from faint differences
/// in individual pixels, as produced by another macOS version.
class _FuzzyGoldenFileComparator extends LocalFileComparator {
  _FuzzyGoldenFileComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) {
      result.dispose();
      return true;
    }

    final ui.Image? master = result.diffs?['masterImage'];
    final ui.Image? test = result.diffs?['testImage'];
    String details = '';
    if (master != null && test != null) {
      final ByteData expected = (await master.toByteData())!;
      final ByteData actual = (await test.toByteData())!;
      final int totalPixels = expected.lengthInBytes ~/ 4;

      int differingPixels = 0;
      int largestDifference = 0;
      for (int i = 0; i < expected.lengthInBytes; i += 4) {
        int difference = 0;
        for (int channel = 0; channel < 4; channel++) {
          final int channelDifference =
              (expected.getUint8(i + channel) - actual.getUint8(i + channel))
                  .abs();
          if (channelDifference > difference) {
            difference = channelDifference;
          }
        }
        if (difference > largestDifference) {
          largestDifference = difference;
        }
        if (difference > _channelTolerance) {
          differingPixels++;
        }
      }

      if (differingPixels <= totalPixels * _maxDifferingPixelRatio) {
        result.dispose();
        return true;
      }

      details =
          '\n$differingPixels of $totalPixels pixels differ by more than '
          '$_channelTolerance per channel (largest difference: '
          '$largestDifference).';
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw TestFailure('$error$details');
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
