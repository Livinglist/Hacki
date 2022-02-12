import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setUpLocator();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

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
        BlocProvider<StoriesBloc>(
          create: (context) => StoriesBloc(),
        ),
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (context) => AuthBloc(),
        ),
        BlocProvider<PreferenceCubit>(
          lazy: false,
          create: (context) => PreferenceCubit(),
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
