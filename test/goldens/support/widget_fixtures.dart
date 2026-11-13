import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'golden_harness.dart';

/// Absolute metadata keeps these tiles independent of the host clock.
class WidgetStory extends Story {
  const WidgetStory({
    super.url = '',
    super.text = 'A thoughtful discussion about building reliable software.',
  }) : super(
         descendants: 42,
         id: 100,
         score: 256,
         time: 1704067200,
         by: 'alice',
         title: 'Show HN: A small tool with a long title that wraps on phones',
         type: 'story',
         kids: const <int>[],
         parts: const <int>[],
         hidden: false,
       );

  @override
  String get metadata => '256 pts / 42 cmts / alice / Jan 1, 2024';
  @override
  String get metadataWithShortTimeAgoString => metadata;
  @override
  String get simpleMetadata => '256 points 42 comments Jan 1, 2024';
}

Comment widgetComment({
  int id = 101,
  bool hidden = false,
  bool dead = false,
  bool deleted = false,
  bool collapsed = false,
  bool isNew = false,
}) => Comment(
  id: id,
  time: 1704067200,
  parent: 100,
  score: 12,
  by: 'alice',
  text:
      'Readable text with *emphasis*, a quote and https://example.com. '
      'Long comments should wrap across lines at larger font settings.',
  kids: const <int>[],
  dead: dead,
  deleted: deleted,
  hidden: hidden,
  level: 1,
  isFromCache: false,
  isCollapsedByUser: collapsed,
  isNew: isNew,
);

Widget widgetStoriesState(StoriesState state, Widget child) {
  final GoldenStoriesBloc bloc = GoldenStoriesBloc();
  when(() => bloc.state).thenReturn(state);
  return BlocProvider<StoriesBloc>.value(value: bloc, child: child);
}

Widget widgetReminder(Widget child) {
  final GoldenReminderCubit cubit = GoldenReminderCubit();
  when(
    () => cubit.state,
  ).thenReturn(const ReminderState(storyId: 100, hasShown: false));
  return BlocProvider<ReminderCubit>.value(value: cubit, child: child);
}

Widget widgetTabs(Widget child) {
  final GoldenTabCubit tabs = GoldenTabCubit();
  when(() => tabs.state).thenReturn(const TabState(tabs: StoryType.values));
  final GoldenNotificationCubit notifications = GoldenNotificationCubit();
  when(() => notifications.state).thenReturn(
    NotificationState.init().copyWith(unreadCommentsIds: <int>[101]),
  );
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<TabCubit>.value(value: tabs),
      BlocProvider<NotificationCubit>.value(value: notifications),
    ],
    child: child,
  );
}

Widget widgetBlocked(bool blocked, Widget child) {
  if (!blocked) return child;
  final GoldenBlocklistCubit cubit = GoldenBlocklistCubit();
  when(
    () => cubit.state,
  ).thenReturn(const BlocklistState(blocklist: <String>['alice']));
  return BlocProvider<BlocklistCubit>.value(value: cubit, child: child);
}
