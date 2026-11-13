import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:html/parser.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

class _MockRemoteConfigCubit extends Mock implements RemoteConfigCubit {}

void main() {
  group('fetchStoriesStream authors', () {
    late _MockRemoteConfigCubit remoteConfigCubit;
    late MockHackerNewsRepository hackerNewsRepository;
    late HttpClient httpClient;
    late Dio dio;
    late Dio commentsDio;
    late HackerNewsWebRepository repository;
    late String responseHtml;

    setUp(() {
      remoteConfigCubit = _MockRemoteConfigCubit();
      when(() => remoteConfigCubit.state).thenReturn(RemoteConfigState.init());
      hackerNewsRepository = MockHackerNewsRepository();
      httpClient = HttpClient();
      dio = Dio();
      commentsDio = Dio();
      repository = HackerNewsWebRepository(
        remoteConfigCubit: remoteConfigCubit,
        hackerNewsRepository: hackerNewsRepository,
        httpClient: httpClient,
        dio: dio,
        dioWithCache: commentsDio,
      );
      dio.interceptors
        ..clear()
        ..add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  handler.resolve(
                    Response<String>(
                      requestOptions: options,
                      statusCode: HttpStatus.ok,
                      data: responseHtml,
                    ),
                  );
                },
          ),
        );
    });

    tearDown(() {
      dio.close(force: true);
      commentsDio.close(force: true);
      httpClient.close(force: true);
      verifyNever(() => hackerNewsRepository.fetchStory(id: any(named: 'id')));
    });

    for (final bool hasLegacyClass in <bool>[false, true]) {
      test(
        'parses ${hasLegacyClass ? 'legacy' : 'classless'} author links',
        () async {
          responseHtml = _page(
            _storyRows(
              id: 1,
              authorHtml:
                  'by <a href="user?id=alice" '
                  '${hasLegacyClass ? 'class="hnuser"' : ''}>alice</a>',
            ),
          );

          final Story story = await repository
              .fetchStoriesStream(StoryType.top, page: 1)
              .first;

          expect(story.by, 'alice');
          expect(story.id, 1);
          expect(story.title, 'Story 1');
          expect(story.score, 42);
          expect(story.descendants, 7);
        },
      );
    }

    test('parses classless authors with a cached hnuser selector', () async {
      when(() => remoteConfigCubit.state).thenReturn(
        const RemoteConfigState(
          data: <String, dynamic>{'userSelector': '.subline > .hnuser'},
        ),
      );
      responseHtml = _page(
        _storyRows(id: 1, authorHtml: 'by <a href="user?id=alice">alice</a>'),
      );

      final Story story = await repository
          .fetchStoriesStream(StoryType.top, page: 1)
          .first;

      expect(story.by, 'alice');
    });

    test('preserves a matching configured author selector', () async {
      when(() => remoteConfigCubit.state).thenReturn(
        const RemoteConfigState(
          data: <String, dynamic>{'userSelector': '.custom-author'},
        ),
      );
      responseHtml = _page(
        _storyRows(
          id: 1,
          authorHtml: '''
by <a href="user?id=other">other</a>
<span class="custom-author">configured-user</span>''',
        ),
      );

      final Story story = await repository
          .fetchStoriesStream(StoryType.top, page: 1)
          .first;

      expect(story.by, 'configured-user');
    });

    test('reads all author text and trims surrounding whitespace', () async {
      responseHtml = _page(
        _storyRows(
          id: 1,
          authorHtml: '''
by <a href="user?id=alice">
  <span>ali</span>ce
</a>''',
        ),
      );

      final Story story = await repository
          .fetchStoriesStream(StoryType.top, page: 1)
          .first;

      expect(story.by, 'alice');
    });

    test('keeps authors aligned after an authorless story', () async {
      responseHtml = _page(
        '${_storyRows(id: 1, authorHtml: '')}'
        '${_storyRows(id: 2, authorHtml: 'by <a href="user?id=bob">bob</a>')}',
      );

      final List<Story> stories = await repository
          .fetchStoriesStream(StoryType.top, page: 1)
          .take(2)
          .toList();

      expect(stories.map((Story story) => story.id), <int>[1, 2]);
      expect(stories.map((Story story) => story.by), <String>['', 'bob']);
    });
  });

  group('author selector configuration', () {
    test('the default selector matches classless author links', () {
      final String selector = RemoteConfigState.init().userSelector;

      expect(
        parse(
          _page(_storyRows(id: 1, authorHtml: _classlessAuthor)),
        ).querySelector(selector)?.text,
        'alice',
      );
    });

    for (final String path in <String>[
      'assets/remote-config.json',
      'assets/remote-config-dev.json',
    ]) {
      test('$path matches classless author links', () {
        final Map<String, dynamic> config =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final String selector = RemoteConfigState(data: config).userSelector;

        expect(
          parse(
            _page(_storyRows(id: 1, authorHtml: _classlessAuthor)),
          ).querySelector(selector)?.text,
          'alice',
        );
      });
    }
  });
}

const String _classlessAuthor = 'by <a href="user?id=alice">alice</a>';

String _page(String rows) =>
    '''
<table id="hnmain"><tbody><tr><td><table><tbody>
$rows
</tbody></table></td></tr></tbody></table>''';

String _storyRows({required int id, required String authorHtml}) =>
    '''
<tr class="athing" id="$id">
  <td class="title"><span class="titleline">
    <a href="https://example.com/story/$id">Story $id</a>
  </span></td>
</tr>
<tr><td class="subtext"><span class="subline">
  <span class="score" id="score_$id">42 points</span>
  $authorHtml
  <span class="age" title="2026-11-13T17:55:28">
    <a href="item?id=$id">3 hours ago</a>
  </span>
  | <a href="hide?id=$id">hide</a>
  | <a href="item?id=$id">7&nbsp;comments</a>
</span></td></tr>''';
