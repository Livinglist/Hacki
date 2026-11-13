import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flutter widget roots used by application classes, including subclasses of
/// concrete Flutter widgets (for example CustomAppBar extends AppBar).
const Set<String> _flutterWidgetBases = <String>{
  'Widget',
  'StatelessWidget',
  'StatefulWidget',
  'InheritedWidget',
  'InheritedModel',
  'InheritedNotifier',
  'ProxyWidget',
  'ParentDataWidget',
  'RenderObjectWidget',
  'LeafRenderObjectWidget',
  'SingleChildRenderObjectWidget',
  'MultiChildRenderObjectWidget',
  'AnimatedWidget',
  'ImplicitlyAnimatedWidget',
  'AppBar',
};

void main() {
  test('every application widget has an exercised golden scenario', () {
    final Map<String, String> declarations = <String, String>{};
    final RegExp declaration = RegExp(
      r'^(?:(?:abstract|base|final|sealed|interface)\s+)*'
      r'class\s+(\w+)(?:<[^{};]*>)?\s+extends\s+(\w+)',
      multiLine: true,
    );

    for (final File source in _dartFiles('lib')) {
      for (final RegExpMatch match in declaration.allMatches(
        source.readAsStringSync(),
      )) {
        final String name = match.group(1)!;
        declarations['${source.path}#$name'] = match.group(2)!;
      }
    }

    final Set<String> widgetTypes = <String>{..._flutterWidgetBases};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final MapEntry<String, String> declaration in declarations.entries) {
        if (widgetTypes.contains(declaration.value) &&
            widgetTypes.add(declaration.key.split('#').last)) {
          changed = true;
        }
      }
    }

    final Set<String> widgets = <String>{
      for (final String type in declarations.keys)
        if (widgetTypes.contains(type.split('#').last)) type,
    };

    // Read covers metadata rather than imports or arbitrary identifiers. The
    // golden harness also checks that each claimed class is mounted when the
    // screenshot is taken.
    final RegExp coversBlock = RegExp(
      r'covers:\s*(?:const\s+)?(?:<String>)?\s*\{([^}]*)\}',
      dotAll: true,
    );
    final RegExp coverageSet = RegExp(
      r'(?:const|final)\s+Set<String>\s+(\w+)\s*=\s*'
      r'(?:const\s+)?<String>\s*\{([^}]*)\}',
      dotAll: true,
    );
    final RegExp coversReference = RegExp(r'covers:\s*(\w+)\s*[,)]');
    final RegExp spreadReference = RegExp(r'\.\.\.(\w+)');
    final RegExp identifier = RegExp(
      "['\"](lib/[^'\"]+\\.dart#[A-Za-z_][A-Za-z_0-9]*)['\"]",
    );
    final Set<String> covered = <String>{};
    for (final File testFile in _dartFiles('test/goldens')) {
      final String source = testFile.readAsStringSync();
      final Map<String, String> sets = <String, String>{
        for (final RegExpMatch match in coverageSet.allMatches(source))
          match.group(1)!: match.group(2)!,
      };
      final Set<String> references = coversReference
          .allMatches(source)
          .map((RegExpMatch match) => match.group(1)!)
          .toSet();
      for (final RegExpMatch block in coversBlock.allMatches(source)) {
        references.addAll(
          spreadReference
              .allMatches(block.group(1)!)
              .map((RegExpMatch match) => match.group(1)!),
        );
        covered.addAll(
          identifier
              .allMatches(block.group(1)!)
              .map((RegExpMatch match) => match.group(1)!),
        );
      }
      final Set<String> visited = <String>{};
      while (references.isNotEmpty) {
        final String reference = references.first;
        references.remove(reference);
        if (!visited.add(reference)) continue;
        final String? block = sets[reference];
        expect(
          block,
          isNotNull,
          reason:
              'Coverage references must use a literal Set<String> in '
              '${testFile.path}: $reference',
        );
        covered.addAll(
          identifier
              .allMatches(block!)
              .map((RegExpMatch match) => match.group(1)!),
        );
        references.addAll(
          spreadReference
              .allMatches(block)
              .map((RegExpMatch match) => match.group(1)!),
        );
      }
    }

    expect(
      widgets,
      isNotEmpty,
      reason: 'The source inventory must find widgets.',
    );
    expect(
      widgets.difference(covered).toList()..sort(),
      isEmpty,
      reason:
          'Add a real GoldenScenario for each uncovered widget, including '
          'private widgets. List source.dart#Class in its covers metadata.',
    );
    expect(
      covered.difference(widgets).toList()..sort(),
      isEmpty,
      reason:
          'Remove stale coverage metadata after deleting or renaming widgets.',
    );
  });
}

Iterable<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File file) => file.path.endsWith('.dart'));
