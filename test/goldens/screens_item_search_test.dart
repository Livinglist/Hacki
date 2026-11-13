import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/screens/item/widgets/item_screen_web_view.dart';
import 'package:hacki/screens/item/widgets/poll_view.dart';
import 'package:hacki/screens/search/search_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'support/golden_harness.dart';
import 'support/screen_fixtures.dart';

class _CommentsCubit extends MockCubit<CommentsState>
    implements CommentsCubit {}

class _SearchCubit extends MockCubit<SearchState> implements SearchCubit {}

class _EditCubit extends MockCubit<EditState> implements EditCubit {}

class _PollCubit extends MockCubit<PollState> implements PollCubit {}

const Story _story = _GoldenStory();

class _GoldenStory extends Story {
  const _GoldenStory()
    : super(
        id: 42001,
        score: 128,
        time: 1700000000,
        by: 'alice',
        title: 'Ask HN: What are you building this weekend?',
        type: 'story',
        url: '',
        text: 'Share a project, an experiment, or something you learned.',
        kids: const <int>[42002, 42003],
        descendants: 3,
        parts: const <int>[],
        hidden: false,
      );

  @override
  String get timeAgo => '2 hours ago';

  @override
  String get shortTimeAgo => '2h';
}

class _GoldenComment extends Comment {
  _GoldenComment({
    required super.id,
    required super.parent,
    required super.level,
    required super.by,
    required super.text,
  }) : super(
         time: 1700000000,
         score: 1,
         kids: <int>[],
         dead: false,
         deleted: false,
         hidden: false,
         isFromCache: true,
       );

  @override
  String get timeAgo => '1 hour ago';

  @override
  String get shortTimeAgo => '1h';
}

Comment _comment({
  int id = 42002,
  int parent = 42001,
  int level = 0,
  String by = 'bob',
  String text = 'I am building an accessible reader. Small details matter.',
}) => _GoldenComment(id: id, parent: parent, by: by, text: text, level: level);

const Set<String> _itemCoverage = <String>{
  'lib/screens/item/item_screen.dart#ItemScreen',
  'lib/screens/item/widgets/main_view.dart#MainView',
  'lib/screens/item/widgets/main_view.dart#_ParentItemSection',
  'lib/screens/item/widgets/custom_app_bar.dart#CustomAppBar',
  'lib/screens/item/widgets/item_screen_background.dart#ItemScreenBackground',
  'lib/screens/item/widgets/reply_box.dart#ReplyBox',
};

void main() {
  testGoldens('item', <GoldenScenario>[
    GoldenScenario(
      'loading',
      () => _item(status: CommentsStatus.inProgress),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'empty',
      () => _item(status: CommentsStatus.allLoaded),
      exercise: (WidgetTester tester) =>
          tester.pump(const Duration(milliseconds: 1500)),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'comments',
      () => _item(
        comments: <Comment>[
          _comment(),
          _comment(
            id: 42003,
            parent: 42002,
            level: 1,
            by: 'alice',
            text: 'Thanks! Have you tried large text and a narrow screen?',
          ),
          _comment(
            id: 42004,
            by: 'carol',
            text: 'A new project every weekend.',
          ),
        ],
      ),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'comment_thread',
      () => _item(
        item: _comment(),
        comments: <Comment>[
          _comment(
            id: 42003,
            parent: 42002,
            by: 'alice',
            text: 'A thoughtful reply.',
          ),
        ],
      ),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'reply',
      () => _item(
        comments: <Comment>[_comment()],
        editState: EditState(
          text: 'Thank you for sharing!',
          replyingTo: _comment(),
        ),
      ),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'in_thread_search',
      () => _item(comments: <Comment>[_comment()], search: true),
      exercise: (WidgetTester tester) async {
        final IconButton button = tester.widget<IconButton>(
          find
              .ancestor(
                of: find.byTooltip('Search in thread'),
                matching: find.byType(IconButton),
              )
              .first,
        );
        button.onPressed!();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
      covers: <String>{
        ..._itemCoverage,
        'lib/screens/item/widgets/in_thread_search_icon_button.dart#_InThreadSearchView',
      },
    ),
    GoldenScenario(
      'split_view',
      () => _item(comments: <Comment>[_comment()], splitView: true),
      covers: _itemCoverage,
    ),
    GoldenScenario(
      'web_view_sheet',
      () => Stack(
        children: <Widget>[
          ItemScreenWebView(
            url: 'https://example.com/articles/a-calmer-internet',
            controller: ItemScreenWebViewController(),
          ),
        ],
      ),
      setup: installScreenPlatformFakes,
      exercise: (WidgetTester tester) async {
        final GestureDetector handle = tester.widget<GestureDetector>(
          find
              .ancestor(
                of: find.byIcon(Icons.keyboard_arrow_up_rounded),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        handle.onTap!();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
      covers: const <String>{
        'lib/screens/item/widgets/item_screen_web_view.dart#ItemScreenWebView',
        'lib/screens/widgets/web_view_bottom_sheet.dart#WebViewBottomSheet',
        'lib/screens/widgets/web_view_bottom_sheet.dart#_UrlBar',
      },
    ),
    GoldenScenario(
      'poll_loading',
      () => _poll(PollState.init().copyWith(status: Status.inProgress)),
      covers: const <String>{
        'lib/screens/item/widgets/poll_view.dart#PollView',
      },
    ),
    GoldenScenario(
      'poll_results',
      () => _poll(
        PollState(
          totalVotes: 100,
          selections: const <int>{},
          pollOptions: <PollOption>[
            PollOption.fromJson(const <String, dynamic>{
              'id': 42010,
              'parent': 42001,
              'by': 'alice',
              'text': 'Build something useful',
              'score': 75,
            }).copyWith(ratio: 0.75),
            PollOption.fromJson(const <String, dynamic>{
              'id': 42011,
              'parent': 42001,
              'by': 'alice',
              'text': 'Learn a new skill',
              'score': 25,
            }).copyWith(ratio: 0.25),
          ],
          status: Status.success,
        ),
      ),
      covers: const <String>{
        'lib/screens/item/widgets/poll_view.dart#PollView',
      },
    ),
  ]);

  testGoldens('search', <GoldenScenario>[
    for (final SearchStatus status in <SearchStatus>[
      SearchStatus.idle,
      SearchStatus.loading,
      SearchStatus.loaded,
    ])
      GoldenScenario(
        status.name,
        () => _search(SearchState.init().copyWith(status: status)),
        covers: const <String>{
          'lib/screens/search/search_screen.dart#SearchScreen',
        },
      ),
    GoldenScenario(
      'results',
      () => _search(
        SearchState.init().copyWith(
          status: SearchStatus.loaded,
          params: SearchParams.init().copyWith(query: 'building'),
          results: <Item>[_story, _comment()],
        ),
      ),
      covers: const <String>{
        'lib/screens/search/search_screen.dart#SearchScreen',
      },
    ),
    GoldenScenario(
      'filters',
      () => _search(
        SearchState.init().copyWith(
          status: SearchStatus.loaded,
          params: SearchParams.init().copyWith(
            query: 'accessibility',
            sorted: true,
            exactMatch: true,
            filters: <SearchFilter>{
              const StoryFilter(),
              const PostedByFilter(author: 'alice'),
              const PointsFilter(
                points: 100,
                condition: NumericCondition.greaterThan,
              ),
              DateTimeRangeFilter(
                startTime: DateTime(2024),
                endTime: DateTime(2024, 2),
              ),
            },
          ),
        ),
      ),
      covers: const <String>{
        'lib/screens/search/search_screen.dart#SearchScreen',
      },
    ),
  ]);
}

Widget _item({
  Item item = _story,
  CommentsStatus status = CommentsStatus.loaded,
  List<Comment> comments = const <Comment>[],
  EditState editState = const EditState.init(),
  bool splitView = false,
  bool search = false,
}) {
  final _CommentsCubit cubit = _CommentsCubit();
  when(() => cubit.state).thenReturn(
    CommentsState.init(
      isOfflineReading: false,
      item: item,
      fetchMode: FetchMode.eager,
      order: CommentsOrder.natural,
    ).copyWith(
      status: status,
      comments: comments,
      inThreadSearchQuery: search ? 'accessible' : '',
      inThreadSearchStatus: search ? Status.success : Status.idle,
      matchedComments: search ? comments : const <Comment>[],
      idToCommentMap: <int, Comment>{for (final Comment c in comments) c.id: c},
      maxLevel: comments.fold<int>(
        0,
        (int max, Comment c) => c.level > max ? c.level : max,
      ),
    ),
  );
  when(() => cubit.itemScrollController).thenReturn(ItemScrollController());
  when(
    () => cubit.itemPositionsListener,
  ).thenReturn(ItemPositionsListener.create());
  when(() => cubit.globalKeys).thenReturn(<int, GlobalKey>{});
  when(
    () => cubit.currentTips,
  ).thenReturn('Swipe a comment to reveal more actions.');
  when(() => cubit.hasNewComment).thenReturn(false);
  when(() => cubit.inThreadSearchOffset).thenReturn(0);
  for (final Comment comment in comments) {
    when(
      () => cubit.collapsedCount(
        comment,
        countNewComments: any(named: 'countNewComments'),
      ),
    ).thenReturn((0, 0));
  }
  final _EditCubit edit = _EditCubit();
  when(() => edit.state).thenReturn(editState);
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<CommentsCubit>.value(value: cubit),
      BlocProvider<EditCubit>.value(value: edit),
    ],
    child: ItemScreen(
      item: item,
      parentComments: const <Comment>[],
      splitViewEnabled: splitView,
      showBackButton: true,
    ),
  );
}

Widget _search(SearchState state) {
  final _SearchCubit cubit = _SearchCubit();
  when(() => cubit.state).thenReturn(state);
  when(
    () => cubit.textEditingController,
  ).thenReturn(TextEditingController(text: state.params.query));
  return BlocProvider<SearchCubit>.value(
    value: cubit,
    child: const SearchScreen(),
  );
}

Widget _poll(PollState state) {
  final _PollCubit cubit = _PollCubit();
  when(() => cubit.state).thenReturn(state);
  return BlocProvider<PollCubit>.value(
    value: cubit,
    child: const Scaffold(body: Center(child: PollView())),
  );
}
