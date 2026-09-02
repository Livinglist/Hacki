import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/services/services.dart';

void main() {
  group('WebAnalyzer.sanitizeText', () {
    test('decodes numeric html entities', () {
      expect(
        WebAnalyzer.sanitizeText('Foo&#39;s'),
        "Foo's",
      );
      expect(WebAnalyzer.sanitizeText('RSS &#8981;'), 'RSS ⌕');
      expect(WebAnalyzer.sanitizeText('a &#x27;b&#x27;'), "a 'b'");
    });

    test('decodes named html entities', () {
      expect(WebAnalyzer.sanitizeText('AT&amp;T &mdash; foo'), 'AT&T — foo');
    });

    test('removes html comments and tags', () {
      expect(
        WebAnalyzer.sanitizeText('<p>Explore Books</p><!-- Projects --> Links'),
        'Explore Books Links',
      );
      expect(
        WebAnalyzer.sanitizeText('someone: <p>first<i>second</i>'),
        'someone: first second',
      );
    });

    test('keeps text that only looks like markup', () {
      expect(
        WebAnalyzer.sanitizeText('if a < b and c > d'),
        'if a < b and c > d',
      );
    });

    test('collapses whitespace and non breaking spaces', () {
      expect(
        WebAnalyzer.sanitizeText('  foo&nbsp;&nbsp;bar\n\n  baz  '),
        'foo bar baz',
      );
    });

    test('does not turn escaped markup into strippable tags', () {
      expect(WebAnalyzer.sanitizeText('use &lt;b&gt; here'), 'use <b> here');
    });

    test('handles null and empty input', () {
      expect(WebAnalyzer.sanitizeText(null), '');
      expect(WebAnalyzer.sanitizeText(''), '');
    });
  });
}
