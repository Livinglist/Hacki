# Application goldens

The suite captures Hacki's Flutter UI for Android and iOS using deterministic
fixtures. Each scenario runs the full Cartesian product below (36 captures):

| Dimension | Values |
| --- | --- |
| Flutter target platform | Android, iOS |
| Logical viewport | Compact phone 320 × 640, phone 390 × 844, tablet 1024 × 768 |
| Device pixel ratio | 1, 2 |
| App font size and text scale | Small (15pt, 0.85×), regular (16pt, 1×), extra extra large (19pt, 1.5×) |

The platform controls Flutter's platform-specific layout and controls. These are
widget tests, not screenshots from Android emulators or iOS simulators. Native
camera, decoded video, and web content sit outside the Flutter renderer; their platform fakes
allow the surrounding application controls to be captured. Native camera output,
web rendering, system permission dialogs, and operating-system chrome require
device integration tests.

## Run and update

Use Linux and the repository's pinned Flutter submodule for baseline generation
and comparison:

```sh
git submodule update --init --recursive
submodules/flutter/bin/flutter pub get
submodules/flutter/bin/flutter test test/goldens --concurrency=2
```

Regenerate only when the UI change is intended:

```sh
submodules/flutter/bin/flutter test test/goldens --update-goldens --concurrency=2
git diff --stat -- test/goldens
```

Review the changed PNGs before committing. A missing baseline or any pixel
difference fails normal comparison. CI compares committed baselines; it never
updates them. The Golden Tests workflow uses Ubuntu 24.04 and uploads the expected,
actual, and difference images when comparison fails.

The matrix cases carry the `golden` test tag. Build and Commit Guard jobs run
other tests with `--exclude-tags=golden`, while the Linux Golden Tests job runs
this entire directory. Rasterization varies between host operating systems even
when the target platform is the same; Android and iOS cases therefore share one
Linux baseline host.

## Add or change a widget

Create a `GoldenScenario` that builds the real application widget with fixed
data, and declare its coverage using source-qualified names:

```dart
GoldenScenario(
  'example',
  () => const ExampleWidget(),
  covers: <String>{'lib/screens/example_widget.dart#ExampleWidget'},
)
```

Use interactions to expose dialogs, menus, collapsed and expanded states, or
content below the initial viewport. Avoid network calls, wall-clock timestamps,
and unlimited animation settling in fixtures. Keep animation capture times fixed.

`coverage_test.dart` inventories application widget declarations, including private
widgets and subclasses such as `CustomAppBar`, and requires scenario metadata for
each one. The harness checks that a claimed class is actually mounted at capture
time. New widgets and renamed classes therefore require corresponding scenarios;
listing a class without building it does not satisfy a golden test.

The inventory follows application inheritance from known Flutter widget bases.
When introducing a subclass of another concrete Flutter widget, add that Flutter
base to `_flutterWidgetBases` in the coverage test as well.
