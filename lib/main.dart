import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
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
      ],
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
    );
  }
}
