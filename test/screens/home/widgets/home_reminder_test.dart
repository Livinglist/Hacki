import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/home/widgets/mobile_home_screen.dart';
import 'package:hacki/screens/home/widgets/tablet_home_screen.dart';
import 'package:hacki/screens/widgets/countdown_reminder.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class _MockReminderCubit extends MockCubit<ReminderState>
    implements ReminderCubit {}

class _MockSplitViewCubit extends MockCubit<SplitViewState>
    implements SplitViewCubit {}

void main() {
  late _MockStoriesBloc storiesBloc;
  late _MockReminderCubit reminderCubit;
  late _MockSplitViewCubit splitViewCubit;
  late StreamController<StoriesState> stories;
  late StreamController<ReminderState> reminders;

  setUp(() {
    storiesBloc = _MockStoriesBloc();
    reminderCubit = _MockReminderCubit();
    splitViewCubit = _MockSplitViewCubit();
    stories = StreamController<StoriesState>.broadcast(sync: true);
    reminders = StreamController<ReminderState>.broadcast(sync: true);
    when(
      () => splitViewCubit.state,
    ).thenReturn(const SplitViewState.init().copyWith(enabled: true));
    when(() => reminderCubit.onDismiss()).thenAnswer((_) {
      reminders.add(reminderCubit.state.copyWith(hasShown: true));
    });
  });

  tearDown(() async {
    await stories.close();
    await reminders.close();
  });

  Future<void> withHome(
    WidgetTester tester, {
    required bool tablet,
    required Future<void> Function() check,
    StoriesState initialStories = const StoriesState.init(),
    ReminderState initialReminder = const ReminderState.init(),
  }) async {
    whenListen(storiesBloc, stories.stream, initialState: initialStories);
    whenListen(reminderCubit, reminders.stream, initialState: initialReminder);
    await tester.binding.setSurfaceSize(
      tablet ? const Size(1024, 768) : const Size(390, 844),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    try {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<StoriesBloc>.value(value: storiesBloc),
            BlocProvider<ReminderCubit>.value(value: reminderCubit),
            BlocProvider<SplitViewCubit>.value(value: splitViewCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.theme(
              ColorScheme.fromSeed(seedColor: Palette.deepOrange),
              Font.robotoSlab,
              isDarkModeEnabled: false,
              isTrueDarkModeEnabled: false,
            ),
            home: Scaffold(
              body: tablet
                  ? const TabletHomeScreen(homeScreen: SizedBox.expand())
                  : const MobileHomeScreen(homeScreen: SizedBox.expand()),
            ),
          ),
        ),
      );
      await check();
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      // CountdownReminder's delayed start is guarded by mounted, but its
      // three-second timer must still be drained after disposing the widget.
      await tester.pump(const Duration(seconds: 3));
    }
  }

  StoriesState downloading({int downloaded = 0}) =>
      const StoriesState.init().copyWith(
        downloadStatus: StoriesDownloadStatus.downloading,
        storiesDownloaded: downloaded,
        storiesToBeDownloaded: 10,
      );

  for (final bool tablet in <bool>[false, true]) {
    group(tablet ? 'tablet home' : 'mobile home', () {
      testWidgets('downloads replace an undismissed reminder and update', (
        WidgetTester tester,
      ) async {
        await withHome(
          tester,
          tablet: tablet,
          initialReminder: const ReminderState(storyId: 123, hasShown: false),
          check: () async {
            await tester.pump(const Duration(seconds: 3));
            expect(find.text('Pick up where you left off'), findsOneWidget);
            final State<StatefulWidget> reminderState = tester.state(
              find.byType(CountdownReminder),
            );

            stories.add(downloading());
            await tester.pump();
            expect(find.byType(CountdownReminder), findsNothing);
            expect(find.text('Pick up where you left off'), findsNothing);
            expect(find.text('Downloading stories (0/10)'), findsOneWidget);

            stories.add(downloading(downloaded: 4));
            await tester.pump();
            expect(find.text('Downloading stories (4/10)'), findsOneWidget);

            stories.add(
              downloading().copyWith(
                downloadStatus: StoriesDownloadStatus.canceled,
              ),
            );
            await tester.pump();
            expect(find.textContaining('Downloading stories ('), findsNothing);
            expect(find.byType(CountdownReminder), findsOneWidget);
            expect(find.text('Pick up where you left off'), findsOneWidget);
            expect(
              tester.state(find.byType(CountdownReminder)),
              same(reminderState),
            );
          },
        );
      });

      testWidgets('a later download appears after the reminder times out', (
        WidgetTester tester,
      ) async {
        await withHome(
          tester,
          tablet: tablet,
          check: () async {
            // There is no last-read story, so the reminder is never visible.
            // Downloads must still appear after that reminder has timed out.
            expect(find.byType(CountdownReminder), findsOneWidget);
            expect(find.text('Pick up where you left off'), findsNothing);
            await tester.pump(const Duration(seconds: 3));
            await tester.pump(const Duration(seconds: 11));
            await tester.pump();
            verify(() => reminderCubit.onDismiss()).called(1);
            expect(find.text('Pick up where you left off'), findsNothing);

            stories.add(downloading(downloaded: 2));
            await tester.pump();
            expect(find.text('Downloading stories (2/10)'), findsOneWidget);
          },
        );
      });

      testWidgets('an existing download hides on every terminal status', (
        WidgetTester tester,
      ) async {
        await withHome(
          tester,
          tablet: tablet,
          initialStories: downloading(downloaded: 3),
          check: () async {
            expect(find.text('Downloading stories (3/10)'), findsOneWidget);

            for (final StoriesDownloadStatus status in <StoriesDownloadStatus>[
              StoriesDownloadStatus.finished,
              StoriesDownloadStatus.canceled,
              StoriesDownloadStatus.failure,
            ]) {
              stories.add(downloading().copyWith(downloadStatus: status));
              await tester.pump();
              expect(
                find.textContaining('Downloading stories ('),
                findsNothing,
              );
              expect(find.text('Pick up where you left off'), findsNothing);

              stories.add(downloading(downloaded: 1));
              await tester.pump();
              expect(find.text('Downloading stories (1/10)'), findsOneWidget);
            }
          },
        );
      });
    });
  }
}
