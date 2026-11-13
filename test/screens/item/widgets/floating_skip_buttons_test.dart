import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockCommentsCubit extends MockCubit<CommentsState>
    implements CommentsCubit {}

class _MockThreadNavigationButtonCubit
    extends MockCubit<ThreadNavigationButtonState>
    implements ThreadNavigationButtonCubit {}

void main() {
  late _MockThreadNavigationButtonCubit buttonCubit;

  Future<void> pumpButtons(
    WidgetTester tester, {
    required PreferenceState preferenceState,
  }) async {
    final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(preferenceState);

    buttonCubit = _MockThreadNavigationButtonCubit();
    when(
      () => buttonCubit.state,
    ).thenReturn(ThreadNavigationButtonState.init());

    final _MockCommentsCubit commentsCubit = _MockCommentsCubit();
    when(() => commentsCubit.state).thenReturn(
      CommentsState.init(
        isOfflineReading: false,
        item: Story.placeholder(),
        fetchMode: FetchMode.eager,
        order: CommentsOrder.natural,
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<ThreadNavigationButtonCubit>.value(value: buttonCubit),
          BlocProvider<CommentsCubit>.value(value: commentsCubit),
        ],
        child: FeatureDiscovery(
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  FloatingSkipButtons(),
                  FloatingHistoryButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FloatingSkipButtons', () {
    testWidgets('shows the back and forward buttons by default', (
      WidgetTester tester,
    ) async {
      await pumpButtons(tester, preferenceState: PreferenceState.init());

      expect(find.byIcon(Icons.turn_left), findsOneWidget);
      expect(find.byIcon(Icons.turn_right), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('hides the back and forward buttons when turned off', (
      WidgetTester tester,
    ) async {
      await pumpButtons(
        tester,
        preferenceState: PreferenceState.init().copyWithPreference(
          const HistoryButtonsPreference(val: false),
        ),
      );

      expect(find.byIcon(Icons.turn_left), findsNothing);
      expect(find.byIcon(Icons.turn_right), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('keeps all four buttons in one group by default', (
      WidgetTester tester,
    ) async {
      await pumpButtons(tester, preferenceState: PreferenceState.init());

      expect(
        find.descendant(
          of: find.byType(FloatingSkipButtons),
          matching: find.byType(FloatingActionButton),
        ),
        findsNWidgets(4),
      );
      expect(
        find.descendant(
          of: find.byType(FloatingHistoryButtons),
          matching: find.byType(FloatingActionButton),
        ),
        findsNothing,
      );
    });

    group('when the back and forward buttons are not combined', () {
      final PreferenceState separate = PreferenceState.init()
          .copyWithPreference(
            const CombineHistoryButtonsPreference(val: false),
          );

      testWidgets('shows them as their own group', (WidgetTester tester) async {
        await pumpButtons(tester, preferenceState: separate);

        final Finder skipGroup = find.byType(FloatingSkipButtons);
        final Finder historyGroup = find.byType(FloatingHistoryButtons);

        expect(
          find.descendant(
            of: skipGroup,
            matching: find.byType(FloatingActionButton),
          ),
          findsNWidgets(2),
        );
        expect(
          find.descendant(
            of: skipGroup,
            matching: find.byIcon(Icons.turn_left),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: historyGroup,
            matching: find.byIcon(Icons.turn_left),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: historyGroup,
            matching: find.byIcon(Icons.turn_right),
          ),
          findsOneWidget,
        );
      });

      testWidgets('places the two groups side by side without overlapping', (
        WidgetTester tester,
      ) async {
        await pumpButtons(tester, preferenceState: separate);

        final Rect skipGroup = tester.getRect(
          find
              .descendant(
                of: find.byType(FloatingSkipButtons),
                matching: find.byType(Column),
              )
              .first,
        );
        final Rect historyGroup = tester.getRect(
          find
              .descendant(
                of: find.byType(FloatingHistoryButtons),
                matching: find.byType(Column),
              )
              .first,
        );

        expect(skipGroup.overlaps(historyGroup), isFalse);
        expect(historyGroup.right, lessThanOrEqualTo(skipGroup.left));
        expect(historyGroup.bottom, skipGroup.bottom);
      });

      testWidgets('dragging them only moves their own group', (
        WidgetTester tester,
      ) async {
        await pumpButtons(tester, preferenceState: separate);

        await tester.drag(find.byIcon(Icons.turn_left), const Offset(-40, -60));
        await tester.pumpAndSettle();

        verify(
          () => buttonCubit.updateHistoryButtonPosition(any(), any()),
        ).called(greaterThan(0));
        verifyNever(() => buttonCubit.updateButtonPosition(any(), any()));
      });

      testWidgets('dragging the skip buttons does not move them', (
        WidgetTester tester,
      ) async {
        await pumpButtons(tester, preferenceState: separate);

        await tester.drag(
          find.byIcon(Icons.keyboard_arrow_up),
          const Offset(-40, -60),
        );
        await tester.pumpAndSettle();

        verify(
          () => buttonCubit.updateButtonPosition(any(), any()),
        ).called(greaterThan(0));
        verifyNever(
          () => buttonCubit.updateHistoryButtonPosition(any(), any()),
        );
      });

      testWidgets('shows neither when the buttons are turned off', (
        WidgetTester tester,
      ) async {
        await pumpButtons(
          tester,
          preferenceState: separate.copyWithPreference(
            const HistoryButtonsPreference(val: false),
          ),
        );

        expect(find.byIcon(Icons.turn_left), findsNothing);
        expect(find.byIcon(Icons.turn_right), findsNothing);
      });
    });
  });
}
