import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

void main() {
  late MockSembastRepository sembastRepository;
  late _RecordingHnClient httpClient;
  late HackerNewsRepository repository;

  setUpAll(() {
    registerFallbackValue(
      Comment.fromJson(<String, dynamic>{
        'id': 0,
        'type': 'comment',
        'by': 'tester',
        'time': 0,
        'text': '',
        'parent': 0,
        'kids': <int>[],
      }),
    );
  });

  setUp(() {
    if (locator.isRegistered<Logger>()) {
      locator.unregister<Logger>();
    }
    locator.registerSingleton<Logger>(MockLogger());

    sembastRepository = MockSembastRepository();
    when(
      () => sembastRepository.getCachedComment(id: any(named: 'id')),
    ).thenAnswer((_) async => null);
    when(
      () => sembastRepository.cacheComment(any()),
    ).thenAnswer((_) async => <String, Object?>{});

    httpClient = _RecordingHnClient(
      delay: const Duration(milliseconds: 40),
      items: <int, Map<String, dynamic>>{
        1: _commentJson(id: 1, kids: <int>[2, 5]),
        2: _commentJson(id: 2, kids: <int>[3, 4]),
        3: _commentJson(id: 3),
        4: _commentJson(id: 4),
        5: _commentJson(id: 5, kids: <int>[6]),
        6: _commentJson(id: 6),
      },
    );

    repository = HackerNewsRepository(
      firebaseClient: FirebaseClient.anonymous(client: httpClient),
      sembastRepository: sembastRepository,
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  test(
    'fetchAllCommentsRecursivelyStream emits DFS order and overlaps requests',
    () async {
      final List<int> ids = await repository
          .fetchAllCommentsRecursivelyStream(ids: <int>[1])
          .map((Comment comment) => comment.id)
          .toList();

      expect(ids, <int>[1, 2, 3, 4, 5, 6]);
      expect(httpClient.maxInFlight, greaterThan(1));
    },
  );

  test(
    'fetchCommentsStream preserves sibling order while overlapping',
    () async {
      final List<int> ids = await repository
          .fetchCommentsStream(ids: <int>[3, 4, 6])
          .map((Comment comment) => comment.id)
          .toList();

      expect(ids, <int>[3, 4, 6]);
      expect(httpClient.maxInFlight, greaterThan(1));
    },
  );
}

Map<String, dynamic> _commentJson({
  required int id,
  List<int> kids = const <int>[],
}) {
  return <String, dynamic>{
    'id': id,
    'type': 'comment',
    'by': 'tester',
    'time': 1,
    'text': 'comment $id',
    'parent': 0,
    'kids': kids,
  };
}

class _RecordingHnClient extends BaseClient {
  _RecordingHnClient({required this.items, required this.delay});

  final Map<int, Map<String, dynamic>> items;
  final Duration delay;
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    _inFlight++;
    maxInFlight = max(maxInFlight, _inFlight);
    try {
      await Future<void>.delayed(delay);
      final String fileName = request.url.pathSegments.last;
      final int id = int.parse(fileName.split('.').first);
      final Map<String, dynamic>? item = items[id];
      if (item == null) {
        return StreamedResponse(
          Stream<List<int>>.value(utf8.encode('null')),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return StreamedResponse(
        Stream<List<int>>.value(utf8.encode(jsonEncode(item))),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    } finally {
      _inFlight--;
    }
  }
}
