import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/models/menu_action.dart';
import 'package:hacki/screens/item/widgets/more_popup_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockFavCubit extends MockCubit<FavState> implements FavCubit {}

final Comment _comment = Comment.fromJson(const <String, dynamic>{
  'id': 1,
  'by': 'pg',
  'text': 'A comment',
});

void main() {
  late MockHackerNewsRepository hackerNewsRepository;
  late _MockPreferenceCubit preferenceCubit;
  late _MockAuthBloc authBloc;
  late _MockFavCubit favCubit;

  setUp(() {
    final MockPreferenceRepository preferenceRepository =
        MockPreferenceRepository();
    when(
      () => preferenceRepository.vote(
        submittedTo: any(named: 'submittedTo'),
        from: any(named: 'from'),
      ),
    ).thenAnswer((_) async => null);
    hackerNewsRepository = MockHackerNewsRepository();
    when(
      () => hackerNewsRepository.fetchUser(id: any(named: 'id')),
    ).thenAnswer((_) async => const User.emptyWithId('pg'));

    locator
      ..registerSingleton<PreferenceRepository>(preferenceRepository)
      ..registerSingleton<AuthRepository>(MockAuthRepository())
      ..registerSingleton<HackerNewsRepository>(hackerNewsRepository);

    preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthState.init());
    favCubit = _MockFavCubit();
    when(() => favCubit.state).thenReturn(FavState.init());
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> openMenu(
    WidgetTester tester, {
    Item? item,
    bool isBlocked = false,
    bool withCallbacks = true,
    VoidCallback? onReplyTapped,
    ValueChanged<MenuAction?>? onResult,
    Size size = const Size(390, 1000),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final MenuAction? result =
                    await showModalBottomSheet<MenuAction>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) => SafeArea(
                        child: MorePopupMenu(
                          item: item ?? _comment,
                          isBlocked: isBlocked,
                          onLoginTapped: () {},
                          onSearchInThreadTapped: withCallbacks ? () {} : null,
                          onReplyTapped: withCallbacks
                              ? onReplyTapped ?? () {}
                              : null,
                          onViewInSeparateThreadTapped: withCallbacks
                              ? () {}
                              : null,
                        ),
                      ),
                    );
                onResult?.call(result);
              },
              child: const Text('Open menu'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<FavCubit>.value(value: favCubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();
  }

  List<String?> labels(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((ListTile tile) => (tile.title! as Text).data)
      .toList();

  testWidgets('uses saved order and omits disabled actions', (
    WidgetTester tester,
  ) async {
    final ItemMenuConfiguration configuration = ItemMenuConfiguration(
      order: <ItemMenuAction>[
        ItemMenuAction.share,
        ItemMenuAction.reply,
        ItemMenuAction.upvote,
      ],
      disabled: <ItemMenuAction>[
        ItemMenuAction.viewProfile,
        ItemMenuAction.downvote,
      ],
    );
    when(() => preferenceCubit.state).thenReturn(
      PreferenceState.init().copyWithPreference(
        ItemMenuActionsPreference(val: configuration.encode()),
      ),
    );

    await openMenu(tester);

    expect(labels(tester).take(3), <String>['Share', 'Reply', 'Upvote']);
    expect(find.text('Downvote'), findsNothing);
    expect(find.text('pg'), findsNothing);
    expect(labels(tester).last, 'Cancel');
    verifyNever(() => hackerNewsRepository.fetchUser(id: any(named: 'id')));
  });

  testWidgets('keeps actions limited to those available for this item', (
    WidgetTester tester,
  ) async {
    await openMenu(tester, withCallbacks: false);

    expect(find.text('Search in thread'), findsNothing);
    expect(find.text('Reply'), findsNothing);
    expect(find.text('View In Separate Thread'), findsNothing);
    expect(find.text('Search on HN'), findsOneWidget);
  });

  testWidgets('does not offer a separate thread for a story', (
    WidgetTester tester,
  ) async {
    await openMenu(tester, item: Story.placeholder());

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('View In Separate Thread'), findsNothing);
  });

  testWidgets('Cancel remains available when every action is disabled', (
    WidgetTester tester,
  ) async {
    when(() => preferenceCubit.state).thenReturn(
      PreferenceState.init().copyWithPreference(
        ItemMenuActionsPreference(
          val: ItemMenuConfiguration(disabled: ItemMenuAction.values).encode(),
        ),
      ),
    );
    MenuAction? result;
    await openMenu(tester, onResult: (MenuAction? value) => result = value);

    expect(labels(tester), <String>['Cancel']);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, MenuAction.cancel);
  });

  testWidgets('reordered Reply still dismisses and invokes its callback', (
    WidgetTester tester,
  ) async {
    when(() => preferenceCubit.state).thenReturn(
      PreferenceState.init().copyWithPreference(
        ItemMenuActionsPreference(
          val: ItemMenuConfiguration(
            order: <ItemMenuAction>[ItemMenuAction.reply],
          ).encode(),
        ),
      ),
    );
    int replyCount = 0;
    await openMenu(tester, onReplyTapped: () => replyCount++);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(replyCount, 1);
    expect(find.byType(MorePopupMenu), findsNothing);
  });

  testWidgets('preserves favorite and block state labels and action results', (
    WidgetTester tester,
  ) async {
    when(
      () => favCubit.state,
    ).thenReturn(FavState.init().copyWith(favIds: <int>[_comment.id]));
    MenuAction? result;
    await openMenu(
      tester,
      isBlocked: true,
      onResult: (MenuAction? value) => result = value,
    );

    expect(find.text('Unfavorite'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);
    await tester.tap(find.text('Unfavorite'));
    await tester.pumpAndSettle();
    expect(result, MenuAction.fav);
  });

  testWidgets(
    'all actions remain reachable on a small screen with large text',
    (WidgetTester tester) async {
      MenuAction? result;
      await openMenu(
        tester,
        size: const Size(320, 480),
        textScale: 2,
        onResult: (MenuAction? value) => result = value,
      );

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, MenuAction.cancel);
      expect(tester.takeException(), isNull);
    },
  );
}
