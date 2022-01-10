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

  runApp(const HackiApp());
}

class HackiApp extends StatelessWidget {
  const HackiApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // This widget is the root of your application.
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
          create: (context) => HistoryCubit(authBloc: context.read<AuthBloc>()),
        ),
        BlocProvider<FavCubit>(
          lazy: false,
          create: (context) => FavCubit(authBloc: context.read<AuthBloc>()),
        ),
        BlocProvider<BlocklistCubit>(
          lazy: false,
          create: (context) => BlocklistCubit(),
        ),
        BlocProvider<SearchCubit>(
          lazy: false,
          create: (context) => SearchCubit(),
        ),
      ],
      child: FeatureDiscovery(
        child: MaterialApp(
          title: 'Hacki',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
          ),
          darkTheme: ThemeData.dark(),
          navigatorKey: navigatorKey,
          onGenerateRoute: CustomRouter.onGenerateRoute,
          initialRoute: HomeScreen.routeName,
        ),
      ),
    );
  }
}
