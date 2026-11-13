import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/screens/settings/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'support/fake_video_platform.dart';
import 'support/golden_harness.dart';
import 'support/widget_fixtures.dart';

class _Preference extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _Stories extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _Proxy extends MockCubit<NetworkProxyState>
    implements NetworkProxyCubit {}

class _Favorites extends MockCubit<FavState> implements FavCubit {}

class _Pins extends MockCubit<PinState> implements PinCubit {}

class _Comments extends MockCubit<CommentsState> implements CommentsCubit {}

const Story _story = Story(
  id: 100,
  descendants: 3,
  score: 42,
  time: 0,
  by: 'ada',
  title: 'Ask HN: What are you building?',
  type: 'story',
  url: '',
  text: 'Share your weekend projects.',
  kids: <int>[101],
  parts: <int>[],
  hidden: false,
);
final Comment _comment = Comment(
  id: 101,
  time: 0,
  parent: 100,
  score: 1,
  by: 'grace',
  text: 'A reply with two children.',
  kids: const <int>[102, 103],
  dead: false,
  deleted: false,
  hidden: false,
  level: 0,
  isFromCache: false,
);

Widget _withPreferences(PreferenceState state, Widget child) {
  return Builder(
    builder: (BuildContext context) {
      final PreferenceState matrix = context.read<PreferenceCubit>().state;
      final _Preference cubit = _Preference();
      when(() => cubit.state).thenReturn(
        state
            .copyWithPreference(FontSizePreference(val: matrix.fontSize.index))
            .copyWithPreference(
              TextScaleFactorPreference(val: matrix.textScaleFactor),
            ),
      );
      return BlocProvider<PreferenceCubit>.value(value: cubit, child: child);
    },
  );
}

Widget _withStories(StoriesState state, Widget child) {
  final _Stories bloc = _Stories();
  when(() => bloc.state).thenReturn(state);
  return BlocProvider<StoriesBloc>.value(value: bloc, child: child);
}

Widget _withAuth(AuthState state, Widget child) {
  final _Auth bloc = _Auth();
  when(() => bloc.state).thenReturn(state);
  return BlocProvider<AuthBloc>.value(value: bloc, child: child);
}

Widget _withProxy(NetworkProxy proxy, Widget child) {
  final _Proxy cubit = _Proxy();
  when(
    () => cubit.state,
  ).thenReturn(NetworkProxyState(proxy: proxy, isAppliedToWebViews: true));
  return BlocProvider<NetworkProxyCubit>.value(value: cubit, child: child);
}

Widget _toolbar({bool selected = false}) {
  final _Favorites favorites = _Favorites();
  when(() => favorites.state).thenReturn(
    FavState.init().copyWith(favIds: selected ? <int>[_story.id] : <int>[]),
  );
  final _Pins pins = _Pins();
  when(() => pins.state).thenReturn(
    PinState.init().copyWith(
      pinnedStoriesIds: selected ? <int>[_story.id] : <int>[],
    ),
  );
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<FavCubit>.value(value: favorites),
      BlocProvider<PinCubit>.value(value: pins),
    ],
    child: Builder(
      builder: (BuildContext context) => Scaffold(
        appBar: CustomAppBar(
          context: context,
          item: _story,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onFontSizeTap: () {},
          fontSizeIconButtonKey: GlobalKey(),
        ),
        body: LazyFetchLoadButton(comment: _comment),
      ),
    ),
  );
}

Widget _navigation({bool separate = false, bool historyEnabled = true}) {
  final PreferenceState preference = PreferenceState.init()
      .copyWithPreference(CombineHistoryButtonsPreference(val: !separate))
      .copyWithPreference(HistoryButtonsPreference(val: historyEnabled));
  final _Comments comments = _Comments();
  when(() => comments.state).thenReturn(
    CommentsState.init(
      isOfflineReading: false,
      item: _story,
      fetchMode: FetchMode.eager,
      order: CommentsOrder.natural,
    ).copyWith(
      navigationStack: const <NavigationAnchor>[
        NavigationAnchor(itemId: 100, alignment: 0),
        NavigationAnchor(itemId: 101, alignment: 0.2),
        NavigationAnchor(itemId: 102, alignment: 0.4),
      ],
      navigationIndex: 1,
    ),
  );
  return _withPreferences(
    preference,
    BlocProvider<CommentsCubit>.value(
      value: comments,
      child: const Stack(
        children: <Widget>[FloatingSkipButtons(), FloatingHistoryButtons()],
      ),
    ),
  );
}

Widget _moreMenu({bool blocked = false}) => SingleChildScrollView(
  key: const Key('more-menu-scroll'),
  child: MorePopupMenu(
    item: blocked ? _comment : _story,
    isBlocked: blocked,
    onLoginTapped: () {},
    onReplyTapped: () {},
    onSearchInThreadTapped: () {},
    onViewInSeparateThreadTapped: () {},
  ),
);

Widget _timeMachine() {
  final _Comments comments = _Comments();
  when(() => comments.state).thenReturn(
    CommentsState.init(
      isOfflineReading: false,
      item: const WidgetStory(),
      fetchMode: FetchMode.eager,
      order: CommentsOrder.natural,
    ),
  );
  final ScrollController controller = ScrollController();
  addTearDown(controller.dispose);
  return _withPreferences(
    PreferenceState.init().copyWithPreference(
      DateFormatPreference(val: DateDisplayFormat.yMMMd.index),
    ),
    TimeMachineDialog(
      comment: _comment,
      commentsCubit: comments,
      deviceType: DeviceScreenType.mobile,
      scrollController: controller,
    ),
  );
}

const Set<String> _toolbarCoverage = <String>{
  'lib/screens/item/widgets/custom_app_bar.dart#CustomAppBar',
  'lib/screens/item/widgets/fav_icon_button.dart#FavIconButton',
  'lib/screens/item/widgets/pin_icon_button.dart#PinIconButton',
  'lib/screens/item/widgets/settings_button.dart#SettingsButton',
  'lib/screens/item/widgets/in_thread_search_icon_button.dart#InThreadSearchIconButton',
  'lib/screens/item/widgets/lazy_fetch_load_button.dart#LazyFetchLoadButton',
};
const Set<String> _navigationCoverage = <String>{
  'lib/screens/item/widgets/floating_skip_buttons.dart#FloatingSkipButtons',
  'lib/screens/item/widgets/floating_skip_buttons.dart#FloatingHistoryButtons',
  'lib/screens/item/widgets/floating_skip_buttons.dart#_DraggableButtonGroup',
  'lib/screens/item/widgets/floating_skip_buttons.dart#_BackButton',
  'lib/screens/item/widgets/floating_skip_buttons.dart#_ForwardButton',
  'lib/screens/item/widgets/floating_skip_buttons.dart#_NavigationHistoryButton',
};

void main() {
  testGoldens('widget_controls', <GoldenScenario>[
    const GoldenScenario(
      'more_menu_story',
      _moreMenu,
      covers: <String>{
        'lib/screens/item/widgets/more_popup_menu.dart#MorePopupMenu',
      },
    ),
    GoldenScenario(
      'more_menu_blocked_comment',
      () => _moreMenu(blocked: true),
      covers: const <String>{
        'lib/screens/item/widgets/more_popup_menu.dart#MorePopupMenu',
      },
    ),
    GoldenScenario(
      'more_menu_bottom',
      _moreMenu,
      covers: const <String>{
        'lib/screens/item/widgets/more_popup_menu.dart#MorePopupMenu',
      },
      exercise: (WidgetTester tester) async {
        await tester.drag(
          find.byKey(const Key('more-menu-scroll')),
          const Offset(0, -1200),
        );
        await tester.pump(const Duration(milliseconds: 400));
      },
    ),
    GoldenScenario(
      'time_machine',
      _timeMachine,
      covers: const <String>{
        'lib/screens/item/widgets/time_machine_dialog.dart#TimeMachineDialog',
      },
      setup: () async {
        if (!locator.isRegistered<CommentCache>()) {
          locator.registerSingleton<CommentCache>(CommentCache());
        }
      },
    ),

    GoldenScenario(
      'slide_actions',
      () => const SlideActionSettings(),
      covers: const <String>{
        'lib/screens/settings/widgets/slide_action_settings.dart#SlideActionSettings',
        'lib/screens/settings/widgets/slide_action_settings.dart#_SlideActionMenu',
      },
    ),
    GoldenScenario(
      'slide_actions_menu',
      () => const SlideActionSettings(),
      covers: const <String>{
        'lib/screens/settings/widgets/slide_action_settings.dart#SlideActionSettings',
      },
      exercise: (WidgetTester tester) async {
        await tester.tap(
          find.byKey(const ValueKey<SlideAction>(SlideAction.upvote)),
        );
        await tester.pump(const Duration(milliseconds: 400));
      },
    ),
    GoldenScenario(
      'slide_actions_swapped',
      () => _withPreferences(
        PreferenceState.init().copyWithPreference(
          const SwappedSlidePanesPreference(val: true),
        ),
        const SlideActionSettings(),
      ),
      covers: const <String>{
        'lib/screens/settings/widgets/slide_action_settings.dart#SlideActionSettings',
      },
    ),
    GoldenScenario(
      'tab_order',
      () => const TabBarSettings(),
      covers: const <String>{
        'lib/screens/settings/widgets/tab_bar_settings.dart#TabBarSettings',
      },
    ),
    GoldenScenario(
      'text_scale_setting',
      () => const TextScaleFactorSettings(),
      covers: const <String>{
        'lib/screens/settings/widgets/text_scale_factor_settings.dart#TextScaleFactorSettings',
      },
    ),
    for (final bool offline in <bool>[false, true])
      GoldenScenario(
        'offline_switch_$offline',
        () => _withStories(
          const StoriesState.init().copyWith(isOfflineReading: offline),
          const EnterOfflineModeListTile(),
        ),
        covers: const <String>{
          'lib/screens/settings/widgets/enter_offline_mode_list_tile.dart#EnterOfflineModeListTile',
        },
      ),
    for (final StoriesDownloadStatus status in <StoriesDownloadStatus>[
      StoriesDownloadStatus.idle,
      StoriesDownloadStatus.downloading,
      StoriesDownloadStatus.finished,
      StoriesDownloadStatus.failure,
    ])
      GoldenScenario(
        'offline_download_${status.name}',
        () => _withStories(
          const StoriesState.init().copyWith(
            downloadStatus: status,
            storiesDownloaded: status == StoriesDownloadStatus.idle ? 0 : 12,
            storiesToBeDownloaded: 20,
            downloadTimestamp: status == StoriesDownloadStatus.finished
                ? 0
                : null,
          ),
          const OfflineListTile(),
        ),
        covers: const <String>{
          'lib/screens/settings/widgets/offline_list_tile.dart#OfflineListTile',
        },
      ),
    for (final bool enabled in <bool>[false, true]) ...<GoldenScenario>[
      GoldenScenario(
        'proxy_tile_$enabled',
        () => _withProxy(
          NetworkProxy(
            isEnabled: enabled,
            host: 'proxy.example.com',
            port: 8080,
          ),
          const ProxyListTile(),
        ),
        covers: const <String>{
          'lib/screens/settings/widgets/proxy_list_tile.dart#ProxyListTile',
        },
      ),
      GoldenScenario(
        'proxy_dialog_$enabled',
        () => _withProxy(
          NetworkProxy(
            isEnabled: enabled,
            host: 'proxy.example.com',
            port: 8080,
          ),
          const ProxySettingsDialog(),
        ),
        covers: const <String>{
          'lib/screens/settings/widgets/proxy_settings_dialog.dart#ProxySettingsDialog',
        },
      ),
    ],
    GoldenScenario(
      'proxy_validation_errors',
      () => _withProxy(
        const NetworkProxy(isEnabled: true, host: '', port: null),
        const ProxySettingsDialog(),
      ),
      covers: const <String>{
        'lib/screens/settings/widgets/proxy_settings_dialog.dart#ProxySettingsDialog',
      },
      exercise: (WidgetTester tester) async {
        await tester.tap(find.text('Save'));
        await tester.pump();
      },
    ),
    const GoldenScenario(
      'item_toolbar',
      _toolbar,
      covers: _toolbarCoverage,
      setup: installGoldenVideoPlatform,
    ),
    GoldenScenario(
      'item_toolbar_selected',
      () => _toolbar(selected: true),
      covers: _toolbarCoverage,
      setup: installGoldenVideoPlatform,
    ),
    const GoldenScenario(
      'navigation_combined',
      _navigation,
      covers: _navigationCoverage,
    ),
    GoldenScenario(
      'navigation_separate',
      () => _navigation(separate: true),
      covers: _navigationCoverage,
    ),
    GoldenScenario(
      'navigation_history_disabled',
      () => _navigation(historyEnabled: false),
      covers: const <String>{
        'lib/screens/item/widgets/floating_skip_buttons.dart#FloatingSkipButtons',
      },
    ),
    for (final Status status in <Status>[
      Status.success,
      Status.failure,
      Status.inProgress,
    ])
      GoldenScenario(
        'login_${status.name}',
        () => _withAuth(
          const AuthState.init().copyWith(status: status),
          const LoginDialog(),
        ),
        covers: const <String>{
          'lib/screens/item/widgets/login_dialog.dart#LoginDialog',
        },
      ),
    GoldenScenario(
      'login_agreed',
      () => _withAuth(
        const AuthState.init().copyWith(agreedToEULA: true),
        const LoginDialog(),
      ),
      covers: const <String>{
        'lib/screens/item/widgets/login_dialog.dart#LoginDialog',
      },
    ),
  ]);
}
