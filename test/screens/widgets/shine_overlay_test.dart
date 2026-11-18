import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart'
    show RenderRepaintBoundary, ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:material_ui/material_ui.dart';

class _Pixels {
  const _Pixels(this.bytes, this.width);

  final Uint8List bytes;
  final int width;

  int brightnessAt(int x, int y) {
    final int offset = (y * width + x) * 4;
    return bytes[offset] + bytes[offset + 1] + bytes[offset + 2];
  }

  Color colorAt(int x, int y) {
    final int offset = (y * width + x) * 4;
    return Color.fromARGB(
      bytes[offset + 3],
      bytes[offset],
      bytes[offset + 1],
      bytes[offset + 2],
    );
  }

  bool get isBlack {
    for (int offset = 0; offset < bytes.length; offset += 4) {
      if (bytes[offset] + bytes[offset + 1] + bytes[offset + 2] > 0) {
        return false;
      }
    }
    return true;
  }
}

void main() {
  late GlobalKey targetKey;
  late GlobalKey boundaryKey;
  late ScrollController scrollController;
  late ValueNotifier<double?> targetHeight;
  late int completions;

  setUp(() {
    targetKey = GlobalKey();
    boundaryKey = GlobalKey();
    scrollController = ScrollController();
    targetHeight = ValueNotifier<double?>(80);
    completions = 0;
  });

  tearDown(() {
    scrollController.dispose();
    targetHeight.dispose();
  });

  const Color primary = Color(0xFF40C080);

  Future<void> pumpHighlight(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Duration elapsed = const Duration(milliseconds: 400),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            brightness: brightness,
          ),
        ),
        home: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 60,
                  width: 300,
                  height: 300,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 50,
                        top: 70,
                        width: 180,
                        height: 160,
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          scrollCacheExtent: const ScrollCacheExtent.pixels(
                            1000,
                          ),
                          children: <Widget>[
                            ValueListenableBuilder<double?>(
                              valueListenable: targetHeight,
                              builder: (_, double? height, __) => height == null
                                  ? const SizedBox.shrink()
                                  : SizedBox(key: targetKey, height: height),
                            ),
                            const SizedBox(height: 1000),
                          ],
                        ),
                      ),
                      ShineOverlay(
                        targetKey: targetKey,
                        onDone: () => completions++,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(elapsed);
  }

  Future<_Pixels> capture(WidgetTester tester) async {
    final RenderRepaintBoundary boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    return (await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      final ByteData data = (await image.toByteData())!;
      final _Pixels result = _Pixels(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        image.width,
      );
      image.dispose();
      return result;
    }))!;
  }

  for (final Brightness brightness in Brightness.values) {
    testWidgets('gently flashes the entire tile in $brightness primary color', (
      WidgetTester tester,
    ) async {
      await pumpHighlight(
        tester,
        brightness: brightness,
        elapsed: Duration.zero,
      );
      expect((await capture(tester)).isBlack, isTrue);

      await tester.pump(const Duration(milliseconds: 200));
      final _Pixels fadingIn = await capture(tester);
      final int halfwayBrightness = fadingIn.brightnessAt(180, 170);
      expect(halfwayBrightness, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 200));
      final _Pixels peak = await capture(tester);
      final Color tint = peak.colorAt(180, 170);
      expect(peak.brightnessAt(180, 170), greaterThan(halfwayBrightness));
      expect(tint.r, closeTo(primary.r * 0.16, 1 / 255));
      expect(tint.g, closeTo(primary.g * 0.16, 1 / 255));
      expect(tint.b, closeTo(primary.b * 0.16, 1 / 255));
      for (final Offset point in <Offset>[
        const Offset(91, 131),
        const Offset(268, 131),
        const Offset(91, 208),
        const Offset(268, 208),
      ]) {
        expect(peak.colorAt(point.dx.toInt(), point.dy.toInt()), tint);
      }
      expect(peak.brightnessAt(89, 170), 0);
      expect(peak.brightnessAt(271, 170), 0);

      await tester.pump(const Duration(milliseconds: 200));
      final _Pixels fadingOut = await capture(tester);
      expect(fadingOut.brightnessAt(180, 170), halfwayBrightness);

      await tester.pump(const Duration(milliseconds: 200));
      expect((await capture(tester)).isBlack, isTrue);
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses nested coordinates and follows a target resize', (
    WidgetTester tester,
  ) async {
    await pumpHighlight(tester);
    final _Pixels before = await capture(tester);
    expect(before.brightnessAt(180, 140), greaterThan(0));
    expect(before.brightnessAt(180, 209), greaterThan(0));
    expect(before.brightnessAt(180, 211), 0);

    targetHeight.value = 120;
    await tester.pump(const Duration(milliseconds: 16));
    final _Pixels after = await capture(tester);
    expect(after.brightnessAt(180, 240), greaterThan(0));
    expect(after.brightnessAt(180, 251), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clips partially visible and cached offscreen targets', (
    WidgetTester tester,
  ) async {
    targetHeight.value = 120;
    await pumpHighlight(tester);
    scrollController.jumpTo(60);
    await tester.pump(const Duration(milliseconds: 16));
    final _Pixels partial = await capture(tester);
    expect(partial.brightnessAt(180, 120), 0);
    expect(partial.brightnessAt(180, 140), greaterThan(0));
    expect(partial.brightnessAt(180, 189), greaterThan(0));
    expect(partial.brightnessAt(180, 191), 0);

    scrollController.jumpTo(250);
    await tester.pump(const Duration(milliseconds: 16));
    expect(targetKey.currentContext, isNotNull);
    expect((await capture(tester)).isBlack, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stops painting a removed target and completes once', (
    WidgetTester tester,
  ) async {
    await pumpHighlight(tester);
    expect((await capture(tester)).isBlack, isFalse);

    targetHeight.value = null;
    await tester.pump(const Duration(milliseconds: 16));
    expect(targetKey.currentContext, isNull);
    expect((await capture(tester)).isBlack, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(completions, 1);
  });
}
