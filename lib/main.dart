import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tempDir = await getTemporaryDirectory();
  final tempPath = tempDir.path;
  Hive.init(tempPath);

  await setUpLocator();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  // BlocOverrides.runZoned(
  //   () {
  //     runApp(HackiApp(
  //       savedThemeMode: savedThemeMode,
  //     ));
  //   },
  //   blocObserver: CustomBlocObserver(),
  // );

  // Uncomment code below for running without logging.
  runApp(HackiApp(
    savedThemeMode: savedThemeMode,
  ));
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
      providers: [
        BlocProvider<PreferenceCubit>(
          lazy: false,
          create: (context) => PreferenceCubit(),
        ),
        BlocProvider<StoriesBloc>(
          create: (context) => StoriesBloc(
            preferenceCubit: context.read<PreferenceCubit>(),
          ),
        ),
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (context) => AuthBloc(),
        ),
        BlocProvider<HistoryCubit>(
          lazy: false,
          create: (context) => HistoryCubit(
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<FavCubit>(
          lazy: false,
          create: (context) => FavCubit(
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<BlocklistCubit>(
          lazy: false,
          create: (context) => BlocklistCubit(),
        ),
        BlocProvider<SearchCubit>(
          lazy: false,
          create: (context) => SearchCubit(),
        ),
        BlocProvider<NotificationCubit>(
          lazy: false,
          create: (context) => NotificationCubit(
            authBloc: context.read<AuthBloc>(),
            preferenceCubit: context.read<PreferenceCubit>(),
          ),
        ),
        BlocProvider<PinCubit>(
          lazy: false,
          create: (context) => PinCubit(),
        ),
        BlocProvider<CacheCubit>(
          lazy: false,
          create: (context) => CacheCubit(),
        ),
        BlocProvider<SplitViewCubit>(
          lazy: false,
          create: (context) => SplitViewCubit(),
        ),
        BlocProvider<ReminderCubit>(
          lazy: false,
          create: (context) => ReminderCubit()..init(),
        ),
        BlocProvider<TimeMachineCubit>(
          lazy: false,
          create: (context) => TimeMachineCubit(),
        ),
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(),
        ),
        BlocProvider<EditCubit>(
          create: (context) => EditCubit(),
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
        builder: (theme, darkTheme) {
          final trueDarkTheme = ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.orange,
            canvasColor: Colors.black,
          );
          return BlocBuilder<PreferenceCubit, PreferenceState>(
            buildWhen: (previous, current) =>
                previous.useTrueDark != current.useTrueDark,
            builder: (context, prefState) {
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
