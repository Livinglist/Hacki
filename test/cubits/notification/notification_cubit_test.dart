import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockPreferenceCubit extends Mock implements PreferenceCubit {}

void main() {
  late MockAuthBloc authBloc;
  late MockPreferenceCubit preferenceCubit;
  late MockHackerNewsRepository hackerNewsRepository;
  late MockPreferenceRepository preferenceRepository;
  late MockSembastRepository sembastRepository;
  late NotificationCubit cubit;

  const int storyId = 100;
  const int existingReplyId = 201;
  const int anotherReplyId = 202;
  const int newReplyId = 203;

  const AuthState loggedInState = AuthState(
    user: User.emptyWithId('tester'),
    isLoggedIn: true,
    status: Status.success,
    agreedToEULA: true,
  );

  setUpAll(() {
    registerFallbackValue(
      Comment.fromJson(const <String, dynamic>{
        'id': 0,
        'type': 'comment',
        'by': 'alice',
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

    authBloc = MockAuthBloc();
    preferenceCubit = MockPreferenceCubit();
    hackerNewsRepository = MockHackerNewsRepository();
    preferenceRepository = MockPreferenceRepository();
    sembastRepository = MockSembastRepository();

    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.state).thenReturn(loggedInState);
    when(
      () => preferenceCubit.stream,
    ).thenAnswer((_) => const Stream<PreferenceState>.empty());
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());

    when(
      () => sembastRepository.getIdsOfCommentsRepliedToMe(),
    ).thenAnswer((_) async => <int>[]);
    when(
      () => preferenceRepository.unreadCommentsIds,
    ).thenAnswer((_) async => <int>[]);
    when(
      () => preferenceRepository.hasPushed(any()),
    ).thenAnswer((_) async => false);
    when(
      () => preferenceRepository.updateUnreadCommentsIds(any()),
    ).thenAnswer((_) async {});
    when(
      () => sembastRepository.saveComment(any()),
    ).thenAnswer((_) async => <String, Object?>{});
    when(
      () => sembastRepository.updateIdsOfCommentsRepliedToMe(any()),
    ).thenAnswer((_) async {});
    when(
      () => sembastRepository.updateKidsOf(
        id: any(named: 'id'),
        kids: any(named: 'kids'),
      ),
    ).thenAnswer((_) async => <int>[]);
    when(
      () => hackerNewsRepository.fetchSubmitted(userId: 'tester'),
    ).thenAnswer((_) async => <int>[storyId]);

    cubit = NotificationCubit(
      authBloc: authBloc,
      preferenceCubit: preferenceCubit,
      hackerNewsRepository: hackerNewsRepository,
      preferenceRepository: preferenceRepository,
      sembastRepository: sembastRepository,
    );
  });

  tearDown(() async {
    await cubit.close();
    await locator.reset();
  });

  test(
    'does not mark existing replies unread when kids snapshot is missing',
    () async {
      when(
        () => sembastRepository.kids(of: storyId),
      ).thenAnswer((_) async => null);
      when(() => hackerNewsRepository.fetchItem(id: storyId)).thenAnswer(
        (_) async =>
            _story(id: storyId, kids: <int>[existingReplyId, anotherReplyId]),
      );
      when(
        () => hackerNewsRepository.fetchComment(id: existingReplyId),
      ).thenAnswer((_) async => _comment(id: existingReplyId));
      when(
        () => hackerNewsRepository.fetchComment(id: anotherReplyId),
      ).thenAnswer((_) async => _comment(id: anotherReplyId));

      await cubit.init();

      expect(cubit.state.unreadCommentsIds, isEmpty);
      expect(
        cubit.state.comments.map((Comment comment) => comment.id),
        containsAll(<int>[existingReplyId, anotherReplyId]),
      );
      verifyNever(() => preferenceRepository.updateUnreadCommentsIds(any()));
      verify(
        () => sembastRepository.updateKidsOf(
          id: storyId,
          kids: <int>[existingReplyId, anotherReplyId],
        ),
      ).called(1);
    },
  );

  test('marks a newly appeared kid unread after a snapshot exists', () async {
    when(
      () => sembastRepository.kids(of: storyId),
    ).thenAnswer((_) async => <int>[existingReplyId]);
    when(() => hackerNewsRepository.fetchItem(id: storyId)).thenAnswer(
      (_) async =>
          _story(id: storyId, kids: <int>[existingReplyId, newReplyId]),
    );
    when(
      () => hackerNewsRepository.fetchComment(id: newReplyId),
    ).thenAnswer((_) async => _comment(id: newReplyId));

    await cubit.init();

    expect(cubit.state.unreadCommentsIds, <int>[newReplyId]);
    expect(
      cubit.state.comments.map((Comment comment) => comment.id),
      contains(newReplyId),
    );
    verify(
      () => preferenceRepository.updateUnreadCommentsIds(<int>[newReplyId]),
    ).called(1);
  });

  test(
    'marks the first reply unread when the stored snapshot is empty',
    () async {
      when(
        () => sembastRepository.kids(of: storyId),
      ).thenAnswer((_) async => <int>[]);
      when(
        () => hackerNewsRepository.fetchItem(id: storyId),
      ).thenAnswer((_) async => _story(id: storyId, kids: <int>[newReplyId]));
      when(
        () => hackerNewsRepository.fetchComment(id: newReplyId),
      ).thenAnswer((_) async => _comment(id: newReplyId));

      await cubit.init();

      expect(cubit.state.unreadCommentsIds, <int>[newReplyId]);
    },
  );

  test('does not overwrite kids when the item fetch fails', () async {
    when(
      () => sembastRepository.kids(of: storyId),
    ).thenAnswer((_) async => <int>[existingReplyId]);
    when(
      () => hackerNewsRepository.fetchItem(id: storyId),
    ).thenAnswer((_) async => null);

    await cubit.init();

    expect(cubit.state.unreadCommentsIds, isEmpty);
    verifyNever(
      () => sembastRepository.updateKidsOf(
        id: any(named: 'id'),
        kids: any(named: 'kids'),
      ),
    );
  });

  test(
    'does not overwrite a non-empty snapshot with an empty kids list',
    () async {
      when(
        () => sembastRepository.kids(of: storyId),
      ).thenAnswer((_) async => <int>[existingReplyId]);
      when(
        () => hackerNewsRepository.fetchItem(id: storyId),
      ).thenAnswer((_) async => _story(id: storyId));

      await cubit.init();

      expect(cubit.state.unreadCommentsIds, isEmpty);
      verifyNever(
        () => sembastRepository.updateKidsOf(
          id: any(named: 'id'),
          kids: any(named: 'kids'),
        ),
      );
    },
  );
}

Story _story({required int id, List<int> kids = const <int>[]}) {
  return Story.fromJson(<String, dynamic>{
    'id': id,
    'type': 'story',
    'by': 'tester',
    'time': 1,
    'title': 'Hello',
    'kids': kids,
  });
}

Comment _comment({required int id}) {
  return Comment.fromJson(<String, dynamic>{
    'id': id,
    'type': 'comment',
    'by': 'alice',
    'time': id,
    'text': 'reply $id',
    'parent': 100,
    'kids': const <int>[],
  });
}
