import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/repositories/hckr_news_repository.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  HckrNewsRepository repositoryFor(String body, {int statusCode = 200}) {
    final MockClient client = MockClient((Request request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://hckrnews.com/data/latest.js');
      return Response(body, statusCode);
    });
    addTearDown(client.close);
    return HckrNewsRepository(client: client);
  }

  group('HckrNewsRepository.fetchStoryIds', () {
    test('parses the feed assignment with an optional semicolon', () async {
      for (final String suffix in <String>['', ';']) {
        final HckrNewsRepository repository = repositoryFor('''
var entries =  [{"id":"12","date":200,"homepage":true},
{"id":"9","date":100,"homepage":false}]$suffix
''');

        expect(await repository.fetchStoryIds(), <int>[12, 9]);
      }
    });

    test('orders by front-page arrival rather than submission time', () async {
      final HckrNewsRepository repository = repositoryFor('''
[
  {"id":"30","date":100,"time":"500"},
  {"id":10,"date":"300","time":"100"},
  {"id":"20","date":200,"time":"300"}
]
''');

      expect(await repository.fetchStoryIds(), <int>[10, 20, 30]);
    });

    test(
      'preserves feed order for equal arrival times and removes duplicates',
      () async {
        final HckrNewsRepository repository = repositoryFor('''
[
  {"id":"9","date":200},
  {"id":"12","date":200},
  {"id":"9","date":100}
]
''');

        expect(await repository.fetchStoryIds(), <int>[9, 12]);
      },
    );

    test('accepts an empty feed', () async {
      expect(await repositoryFor('var entries = [];').fetchStoryIds(), isEmpty);
    });

    test('propagates HTTP failure instead of showing an empty feed', () async {
      expect(
        repositoryFor('Service unavailable', statusCode: 503).fetchStoryIds(),
        throwsA(isA<ClientException>()),
      );
    });

    test('propagates network failure', () async {
      final MockClient client = MockClient((Request request) async {
        throw ClientException('Connection failed', request.url);
      });
      addTearDown(client.close);

      expect(
        HckrNewsRepository(client: client).fetchStoryIds(),
        throwsA(isA<ClientException>()),
      );
    });

    for (final String payload in <String>[
      '<html>Server error</html>',
      '{"error":"Unavailable"}',
      'var entries = []; unexpectedCode()',
      '[null]',
      '[{"id":"invalid","date":100}]',
      '[{"id":0,"date":100}]',
      '[{"id":1}]',
      '[{"id":1,"date":"invalid"}]',
    ]) {
      test('rejects malformed payload $payload', () async {
        expect(
          repositoryFor(payload).fetchStoryIds(),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}
