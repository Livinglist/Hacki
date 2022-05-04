import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/utils/utils.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;
import 'package:workmanager/workmanager.dart';

// For receiving payload event from local notifications.
final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    unawaited(
      Workmanager().initialize(
        fetcherCallbackDispatcher,
      ),
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
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
  }

  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath = tempDir.path;
  Hive.init(tempPath);

  await setUpLocator();

  final AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();

  // Uncomment code below for running with logging.
  // BlocOverrides.runZoned(
  //   () {
  //     runApp(
  //       HackiApp(
  //         savedThemeMode: savedThemeMode,
  //       ),
  //     );
  //   },
  //   blocObserver: CustomBlocObserver(),
  // );

  runApp(
    HackiApp(
      savedThemeMode: savedThemeMode,
    ),
  );
}

class HackiApp extends StatelessWidget {
  const HackiApp({
    Key? key,
    this.savedThemeMode,
  }) : super(key: key);

  final AdaptiveThemeMode? savedThemeMode;

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
        BlocProvider<CacheCubit>(
          lazy: false,
          create: (BuildContext context) => CacheCubit(),
        ),
        BlocProvider<SplitViewCubit>(
          lazy: false,
          create: (BuildContext context) => SplitViewCubit(),
        ),
        BlocProvider<ReminderCubit>(
          lazy: false,
          create: (BuildContext context) => ReminderCubit()..init(),
        ),
        BlocProvider<TimeMachineCubit>(
          lazy: false,
          create: (BuildContext context) => TimeMachineCubit(),
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
          primarySwatch: Colors.orange,
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.orange,
        ),
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (ThemeData theme, ThemeData darkTheme) {
          final ThemeData trueDarkTheme = ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.orange,
            canvasColor: Colors.black,
          );
          return BlocBuilder<PreferenceCubit, PreferenceState>(
            buildWhen: (PreferenceState previous, PreferenceState current) =>
                previous.useTrueDark != current.useTrueDark,
            builder: (BuildContext context, PreferenceState prefState) {
              return FeatureDiscovery(
                child: MaterialApp(
                  title: 'Hacki',
                  debugShowCheckedModeBanner: false,
                  theme: prefState.useTrueDark ? trueDarkTheme : theme,
                  darkTheme: prefState.useTrueDark ? trueDarkTheme : darkTheme,
                  navigatorKey: navigatorKey,
                  onGenerateRoute: CustomRouter.onGenerateRoute,
                  initialRoute: HomeScreen.routeName,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
