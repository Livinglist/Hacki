import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/services/fetcher.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:hacki/utils/theme_util.dart';
import 'package:hive/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:workmanager/workmanager.dart';

// For receiving payload event from local notifications.
final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

// For receiving payload event from siri suggestions.
final BehaviorSubject<String?> siriSuggestionSubject =
    BehaviorSubject<String?>();

late final bool isTesting;

void notificationReceiver(NotificationResponse details) =>
    selectNotificationSubject.add(details.payload);

Future<void> main({bool testing = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(Platform.localeName);

  isTesting = testing;

  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath = tempDir.path;
  Hive.init(tempPath);

  await setUpLocator();

  EquatableConfig.stringify = true;

  FlutterError.onError = (FlutterErrorDetails details) {
    locator.get<Logger>().e(
          details.summary,
          error: details.exceptionAsString(),
          stackTrace: details.stack,
        );
  };

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
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationReceiver,
      onDidReceiveNotificationResponse: notificationReceiver,
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
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    final int sdk = androidInfo.version.sdkInt;

    if (sdk > 28) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Palette.transparent,
          systemNavigationBarColor: Palette.transparent,
          systemNavigationBarDividerColor: Palette.transparent,
        ),
      );
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: <SystemUiOverlay>[SystemUiOverlay.top],
    );
  }

  final AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();

  // Uncomment this line to log events from bloc/cubit.
  // Bloc.observer = CustomBlocObserver();

  HydratedBloc.storage = storage;

  VisibilityDetectorController.instance.updateInterval = AppDurations.ms200;

  runApp(
    HackiApp(
      savedThemeMode: savedThemeMode,
    ),
  );
}

class HackiApp extends StatelessWidget {
  const HackiApp({
    super.key,
    this.savedThemeMode,
  });

  final AdaptiveThemeMode? savedThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<PreferenceCubit>(
          lazy: false,
          create: (BuildContext context) => PreferenceCubit(),
        ),
        BlocProvider<FilterCubit>(
          lazy: false,
          create: (BuildContext context) => FilterCubit(),
        ),
        BlocProvider<StoriesBloc>(
          create: (BuildContext context) => StoriesBloc(
            preferenceCubit: context.read<PreferenceCubit>(),
            filterCubit: context.read<FilterCubit>(),
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
        BlocProvider<TabCubit>(
          create: (BuildContext context) => TabCubit(
            preferenceCubit: context.read<PreferenceCubit>(),
          )..init(),
        ),
      ],
      child: BlocConsumer<PreferenceCubit, PreferenceState>(
        listenWhen: (PreferenceState previous, PreferenceState current) =>
            previous.hapticFeedbackEnabled != current.hapticFeedbackEnabled,
        listener: (_, PreferenceState state) {
          HapticFeedbackUtil.enabled = state.hapticFeedbackEnabled;
        },
        buildWhen: (PreferenceState previous, PreferenceState current) =>
            previous.appColor != current.appColor ||
            previous.font != current.font ||
            previous.textScaleFactor != current.textScaleFactor ||
            previous.trueDarkModeEnabled != current.trueDarkModeEnabled,
        builder: (BuildContext context, PreferenceState state) {
          return AdaptiveTheme(
            key: ValueKey<String>(
              '''${state.appColor}${state.font}${state.trueDarkModeEnabled}''',
            ),
            light: ThemeData(
              primaryColor: state.appColor,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: state.appColor,
              ),
              fontFamily: state.font.name,
            ),
            dark: ThemeData(
              brightness: Brightness.dark,
              primaryColor: state.appColor,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: state.appColor,
                brightness: Brightness.dark,
              ),
              fontFamily: state.font.name,
            ),
            initial: savedThemeMode ?? AdaptiveThemeMode.system,
            builder: (ThemeData theme, ThemeData darkTheme) {
              return FutureBuilder<AdaptiveThemeMode?>(
                future: AdaptiveTheme.getThemeMode(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<AdaptiveThemeMode?> snapshot,
                ) {
                  final AdaptiveThemeMode? mode = snapshot.data;
                  ThemeUtil.updateStatusBarSetting(
                    SchedulerBinding
                        .instance.platformDispatcher.platformBrightness,
                    mode,
                  );
                  final bool isDarkModeEnabled =
                      mode == AdaptiveThemeMode.dark ||
                          (mode == AdaptiveThemeMode.system &&
                              View.of(context)
                                      .platformDispatcher
                                      .platformBrightness ==
                                  Brightness.dark);
                  final ColorScheme colorScheme = ColorScheme.fromSeed(
                    brightness:
                        isDarkModeEnabled ? Brightness.dark : Brightness.light,
                    seedColor: state.appColor,
                    background: isDarkModeEnabled && state.trueDarkModeEnabled
                        ? Palette.black
                        : null,
                  );
                  return FeatureDiscovery(
                    child: MediaQuery(
                      data: state.textScaleFactor == 1
                          ? MediaQuery.of(context)
                          : MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.linear(
                                state.textScaleFactor,
                              ),
                            ),
                      child: MaterialApp.router(
                        title: 'Hacki',
                        debugShowCheckedModeBanner: false,
                        theme: ThemeData(
                          colorScheme: colorScheme,
                          fontFamily: state.font.name,
                          dividerTheme: DividerThemeData(
                            color: Palette.grey.withOpacity(0.2),
                          ),
                          switchTheme: SwitchThemeData(
                            trackColor: MaterialStateProperty.resolveWith(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return colorScheme.primary.withOpacity(0.6);
                                } else {
                                  return Palette.grey.withOpacity(0.2);
                                }
                              },
                            ),
                          ),
                          bottomSheetTheme: const BottomSheetThemeData(
                            modalElevation: 8,
                            clipBehavior: Clip.hardEdge,
                            shadowColor: Palette.black,
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkModeEnabled
                                    ? Palette.white
                                    : Palette.black,
                              ),
                            ),
                          ),
                          sliderTheme: SliderThemeData(
                            inactiveTrackColor:
                                colorScheme.primary.withOpacity(0.5),
                            activeTrackColor: colorScheme.primary,
                            thumbColor: colorScheme.primary,
                          ),
                          outlinedButtonTheme: OutlinedButtonThemeData(
                            style: ButtonStyle(
                              side: MaterialStateBorderSide.resolveWith(
                                (_) => const BorderSide(
                                  color: Palette.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        routerConfig: router,
                      ),
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
