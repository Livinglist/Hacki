import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

class _MockPreferenceCubit extends Mock implements PreferenceCubit {}

class _MockFilterCubit extends Mock implements FilterCubit {}

class _MockHideCubit extends Mock implements HideCubit {}

class _MockOfflineRepository extends Mock implements OfflineRepository {}

class _MockHackerNewsWebRepository extends Mock
    implements HackerNewsWebRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late _MockPreferenceCubit preferenceCubit;
  late _MockFilterCubit filterCubit;
  late _MockHideCubit hideCubit;
  late _MockOfflineRepository offlineRepository;
  late MockHackerNewsRepository hackerNewsRepository;
  late _MockHackerNewsWebRepository hackerNewsWebRepository;
  late _MockHistoryRepository historyRepository;
  late MockPreferenceRepository preferenceRepository;

  setUpAll(() {
    registerFallbackValue(StoryType.chronological);
  });

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    preferenceCubit = _MockPreferenceCubit();
    filterCubit = _MockFilterCubit();
    hideCubit = _MockHideCubit();
    offlineRepository = _MockOfflineRepository();
    hackerNewsRepository = MockHackerNewsRepository();
    hackerNewsWebRepository = _MockHackerNewsWebRepository();
    historyRepository = _MockHistoryRepository();
    preferenceRepository = MockPreferenceRepository();

    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    when(
      () => preferenceCubit.stream,
    ).thenAnswer((_) => const Stream<PreferenceState>.empty());
    when(() => filterCubit.state).thenReturn(FilterState.init());
    when(() => hideCubit.isHidden(any())).thenReturn(false);
    when(() => historyRepository.hasRead(any())).thenAnswer((_) async => false);
    when(
      () => hackerNewsRepository.fetchStoriesStream(
        ids: any(named: 'ids'),
        sequential: any(named: 'sequential'),
      ),
    ).thenAnswer((Invocation invocation) {
      final List<int> ids = invocation.namedArguments[#ids]! as List<int>;
      return Stream<Story>.fromIterable(ids.map(_story));
    });
  });

  tearDown(() async {
    await locator.reset();
  });

  StoriesBloc buildBloc() => StoriesBloc(
    preferenceCubit: preferenceCubit,
    filterCubit: filterCubit,
    hideCubit: hideCubit,
    offlineRepository: offlineRepository,
    hackerNewsRepository: hackerNewsRepository,
    hackerNewsWebRepository: hackerNewsWebRepository,
    historyRepository: historyRepository,
    preferenceRepository: preferenceRepository,
  );

  for (final HackerNewsDataSource source in HackerNewsDataSource.values) {
    blocTest<StoriesBloc, StoriesState>(
      'CHRO uses feed IDs and paginates in order with ${source.name} selected',
      setUp: () {
        when(
          () =>
              hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
        ).thenAnswer((_) async => List<int>.from(_feedIds));
      },
      build: buildBloc,
      seed: () => const StoriesState.init().copyWith(dataSource: source),
      act: (StoriesBloc bloc) async {
        await _dispatch(bloc, LoadStories(type: StoryType.chronological));
        expect(_loadedIds(bloc), _feedIds.take(30));
        expect(bloc.state.currentPageByType[StoryType.chronological], 1);

        await _dispatch(bloc, StoriesLoadMore(type: StoryType.chronological));
      },
      verify: (StoriesBloc bloc) {
        expect(_loadedIds(bloc), _feedIds);
        expect(bloc.state.currentPageByType[StoryType.chronological], 2);
        verify(
          () =>
              hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
        ).called(1);
        verify(
          () => hackerNewsRepository.fetchStoriesStream(
            ids: _feedIds.sublist(0, 30),
            sequential: true,
          ),
        ).called(1);
        verify(
          () => hackerNewsRepository.fetchStoriesStream(
            ids: _feedIds.sublist(30),
          ),
        ).called(1);
        verifyNever(
          () => hackerNewsWebRepository.fetchStoriesStream(
            any(),
            page: any(named: 'page'),
          ),
        );
      },
    );
  }

  blocTest<StoriesBloc, StoriesState>(
    'refresh replaces the previous CHRO snapshot with fresh feed IDs',
    setUp: () {
      int fetches = 0;
      when(
        () => hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
      ).thenAnswer((_) async => ++fetches == 1 ? <int>[20, 10] : <int>[5, 20]);
    },
    build: buildBloc,
    seed: () => const StoriesState.init().copyWith(
      dataSource: HackerNewsDataSource.web,
    ),
    act: (StoriesBloc bloc) async {
      await _dispatch(bloc, LoadStories(type: StoryType.chronological));
      await _dispatch(bloc, StoriesRefresh(type: StoryType.chronological));
    },
    verify: (StoriesBloc bloc) {
      expect(_loadedIds(bloc), <int>[5, 20]);
      expect(bloc.state.storyIdsByType[StoryType.chronological], <int>[5, 20]);
      expect(bloc.state.currentPageByType[StoryType.chronological], 1);
      verify(
        () => hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
      ).called(2);
    },
  );

  blocTest<StoriesBloc, StoriesState>(
    'a feed request failure releases loading and allows a refresh retry',
    setUp: () {
      int fetches = 0;
      when(
        () => hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
      ).thenAnswer((_) async {
        if (++fetches == 1) throw Exception('feed unavailable');
        return <int>[20, 10];
      });
    },
    build: buildBloc,
    seed: () => const StoriesState.init().copyWith(
      dataSource: HackerNewsDataSource.web,
    ),
    act: (StoriesBloc bloc) async {
      await _dispatch(
        bloc,
        LoadStories(type: StoryType.chronological),
        status: Status.failure,
      );
      await _dispatch(bloc, StoriesRefresh(type: StoryType.chronological));
    },
    verify: (StoriesBloc bloc) {
      expect(_loadedIds(bloc), <int>[20, 10]);
      expect(bloc.state.statusByType[StoryType.chronological], Status.success);
    },
  );

  blocTest<StoriesBloc, StoriesState>(
    'a failed CHRO page can be retried without skipping stories',
    setUp: () {
      when(
        () => hackerNewsRepository.fetchStoryIds(type: StoryType.chronological),
      ).thenAnswer((_) async => List<int>.from(_feedIds));
      int pageAttempts = 0;
      when(
        () =>
            hackerNewsRepository.fetchStoriesStream(ids: _feedIds.sublist(30)),
      ).thenAnswer((_) {
        if (++pageAttempts == 1) {
          return Stream<Story>.error(Exception('story unavailable'));
        }
        return Stream<Story>.fromIterable(_feedIds.skip(30).map(_story));
      });
    },
    build: buildBloc,
    seed: () => const StoriesState.init().copyWith(
      dataSource: HackerNewsDataSource.web,
    ),
    act: (StoriesBloc bloc) async {
      await _dispatch(bloc, LoadStories(type: StoryType.chronological));
      await _dispatch(
        bloc,
        StoriesLoadMore(type: StoryType.chronological),
        status: Status.failure,
      );
      expect(bloc.state.currentPageByType[StoryType.chronological], 1);
      await _dispatch(bloc, StoriesLoadMore(type: StoryType.chronological));
    },
    verify: (StoriesBloc bloc) {
      expect(_loadedIds(bloc), _feedIds);
      expect(bloc.state.currentPageByType[StoryType.chronological], 2);
    },
  );

  blocTest<StoriesBloc, StoriesState>(
    'offline CHRO loads its cached IDs without requesting the feed',
    setUp: () {
      when(
        () =>
            offlineRepository.getCachedStoryIds(type: StoryType.chronological),
      ).thenAnswer((_) async => <int>[30, 10]);
      when(
        () => offlineRepository.getCachedStoriesStream(ids: <int>[30, 10]),
      ).thenAnswer(
        (_) => Stream<Story>.fromIterable(<Story>[_story(30), _story(10)]),
      );
    },
    build: buildBloc,
    seed: () => const StoriesState.init().copyWith(
      dataSource: HackerNewsDataSource.web,
      isOfflineReading: true,
    ),
    act: (StoriesBloc bloc) =>
        _dispatch(bloc, LoadStories(type: StoryType.chronological)),
    verify: (StoriesBloc bloc) {
      expect(_loadedIds(bloc), <int>[30, 10]);
      verifyNever(
        () => hackerNewsRepository.fetchStoryIds(type: any(named: 'type')),
      );
    },
  );
}

final List<int> _feedIds = List<int>.generate(
  35,
  (int index) => 1000 - index * 7,
);

Iterable<int> _loadedIds(StoriesBloc bloc) => bloc
    .state
    .storiesByType[StoryType.chronological]!
    .map((Story story) => story.id);

Future<void> _dispatch(
  StoriesBloc bloc,
  StoriesEvent event, {
  Status status = Status.success,
}) async {
  final Future<StoriesState> completed = bloc.stream.firstWhere(
    (StoriesState state) =>
        state.statusByType[StoryType.chronological] == status,
  );
  bloc.add(event);
  await completed;
}

Story _story(int id) => Story.fromJson(<String, dynamic>{
  'id': id,
  'type': 'story',
  'by': 'author',
  'time': id,
  'title': 'Story $id',
  'url': 'https://example.com/$id',
});
