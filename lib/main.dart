import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/custom_bloc_observer.dart';
import 'package:hacki/services/fetcher.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hive/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// For receiving payload event from local notifications.
final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

// For receiving payload event from siri suggestions.
final BehaviorSubject<String?> siriSuggestionSubject =
    BehaviorSubject<String?>();

late final bool isTesting;

Future<void> main({bool testing = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  isTesting = testing;

  final HydratedStorage storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );

  if (Platform.isIOS) {
    unawaited(
      Workmanager().initialize(
        fetcherCallbackDispatcher,
      ),
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: selectNotificationSubject.add,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    FlutterSiriSuggestions.instance.configure(
      onLaunch: (Map<String, dynamic> message) async {
        final String? storyId = message['key'] as String?;

        if (storyId == null) return;

        siriSuggestionSubject.add(storyId);
      },
    );
  } else if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: <SystemUiOverlay>[SystemUiOverlay.top],
    );
  }

  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath = tempDir.path;
  Hive.init(tempPath);

  await setUpLocator();

  final AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool trueDarkMode =
      prefs.getBool(const TrueDarkModePreference().key) ?? false;

  Bloc.observer = CustomBlocObserver();
  HydratedBloc.storage = storage;

  runApp(
    HackiApp(
      savedThemeMode: savedThemeMode,
      trueDarkMode: trueDarkMode,
    ),
  );
}

class HackiApp extends StatelessWidget {
  const HackiApp({
    super.key,
    this.savedThemeMode,
    required this.trueDarkMode,
  });

  final AdaptiveThemeMode? savedThemeMode;
  final bool trueDarkMode;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<PreferenceCubit>(
          lazy: false,
          create: (BuildContext context) => PreferenceCubit(),
        ),
        BlocProvider<StoriesBloc>(
          create: (BuildContext context) => StoriesBloc(
            preferenceCubit: context.read<PreferenceCubit>(),
          ),
        ),
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (BuildContext context) => AuthBloc(),
        ),
        BlocProvider<HistoryCubit>(
          lazy: false,
          create: (BuildContext context) => HistoryCubit(
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<FavCubit>(
          lazy: false,
          create: (BuildContext context) => FavCubit(
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<BlocklistCubit>(
          lazy: false,
          create: (BuildContext context) => BlocklistCubit(),
        ),
        BlocProvider<SearchCubit>(
          lazy: false,
          create: (BuildContext context) => SearchCubit(),
        ),
        BlocProvider<NotificationCubit>(
          lazy: false,
          create: (BuildContext context) => NotificationCubit(
            authBloc: context.read<AuthBloc>(),
            preferenceCubit: context.read<PreferenceCubit>(),
          ),
        ),
        BlocProvider<PinCubit>(
          lazy: false,
          create: (BuildContext context) => PinCubit(),
        ),
        BlocProvider<SplitViewCubit>(
          lazy: false,
          create: (BuildContext context) => SplitViewCubit(),
        ),
        BlocProvider<ReminderCubit>(
          lazy: false,
          create: (BuildContext context) => ReminderCubit()..init(),
        ),
        BlocProvider<PostCubit>(
          lazy: false,
          create: (BuildContext context) => PostCubit(),
        ),
        BlocProvider<EditCubit>(
          lazy: false,
          create: (BuildContext context) => EditCubit(),
        ),
      ],
      child: AdaptiveTheme(
        light: ThemeData(
          primarySwatch: Palette.orange,
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Palette.orange,
          canvasColor: trueDarkMode ? Palette.black : null,
        ),
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (ThemeData theme, ThemeData darkTheme) {
          final ThemeData trueDarkTheme = ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Palette.orange,
            canvasColor: Palette.black,
          );
          return FutureBuilder<AdaptiveThemeMode?>(
            future: AdaptiveTheme.getThemeMode(),
            builder: (
              BuildContext context,
              AsyncSnapshot<AdaptiveThemeMode?> snapshot,
            ) {
              final AdaptiveThemeMode? mode = snapshot.data;
              return BlocBuilder<PreferenceCubit, PreferenceState>(
                buildWhen:
                    (PreferenceState previous, PreferenceState current) =>
                        previous.useTrueDark != current.useTrueDark,
                builder: (BuildContext context, PreferenceState prefState) {
                  final bool useTrueDark = prefState.useTrueDark &&
                      (mode == AdaptiveThemeMode.dark ||
                          (mode == AdaptiveThemeMode.system &&
                              SchedulerBinding
                                      .instance.window.platformBrightness ==
                                  Brightness.dark));
                  return FeatureDiscovery(
                    child: MaterialApp(
                      title: 'Hacki',
                      debugShowCheckedModeBanner: false,
                      theme: useTrueDark ? trueDarkTheme : theme,
                      navigatorKey: navigatorKey,
                      navigatorObservers: <NavigatorObserver>[
                        locator.get<RouteObserver<ModalRoute<dynamic>>>(),
                      ],
                      onGenerateRoute: CustomRouter.onGenerateRoute,
                      initialRoute: HomeScreen.routeName,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
