import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/services/services.dart';

void main() {
  group('WebAnalyzer.sanitizeText', () {
    test('decodes numeric html entities', () {
      expect(WebAnalyzer.sanitizeText('Foo&#39;s'), "Foo's");
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

  group('WebAnalyzer.extractSemanticText', () {
    const String articleParagraph =
        '''This is the real opening paragraph of the story, easily long enough to be considered meaningful content.''';
    const String navParagraph =
        'Home Explore Books Projects Links About RSS Contact me Search';
    const String footerParagraph =
        '''The site is run by someone who is a writer, designer and web coder living somewhere beautiful.''';

    test('returns the first meaningful article paragraph', () {
      expect(
        WebAnalyzer.extractSemanticText('''
<html><head><title>t</title></head><body>
<nav><p>$navParagraph</p></nav>
<article><p>Short.</p><p>$articleParagraph</p></article>
<footer><p>$footerParagraph</p></footer>
</body></html>
'''),
        articleParagraph,
      );
    });

    test('ignores paragraphs in page chrome', () {
      expect(
        WebAnalyzer.extractSemanticText('''
<html><body>
<header><p>$navParagraph</p></header>
<footer><p>$footerParagraph</p></footer>
</body></html>
'''),
        isNull,
      );
    });

    test('falls back to any paragraph outside of the chrome', () {
      expect(
        WebAnalyzer.extractSemanticText('''
<html><body>
<nav><p>$navParagraph</p></nav>
<div><p>$articleParagraph</p></div>
</body></html>
'''),
        articleParagraph,
      );
    });

    test('decodes entities in the extracted paragraph', () {
      expect(
        WebAnalyzer.extractSemanticText(
          '<html><body><article><p>Foo&#39;s Bar, '
          'and foo bar.</p></article></body></html>',
        ),
        "Foo's Bar, and foo bar.",
      );
    });

    test('skips short paragraphs', () {
      expect(
        WebAnalyzer.extractSemanticText(
          '<html><body><article><p>Too short.</p></article></body></html>',
        ),
        isNull,
      );
    });

    test('truncates long paragraphs to 300 characters', () {
      final String text = WebAnalyzer.extractSemanticText(
        '<html><body><article><p>${'foo bar foobar' * 100}</p></article>'
        '</body></html>',
      )!;

      expect(text.length, 300);
    });

    test('returns null when there is no body content', () {
      expect(
        WebAnalyzer.extractSemanticText('<html><head></head></html>'),
        isNull,
      );
    });
  });
}
