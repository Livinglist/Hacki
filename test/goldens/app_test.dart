import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/screens/profile/widgets/centered_message_view.dart';
import 'package:material_ui/material_ui.dart';

import 'support/golden_harness.dart';

void main() {
  testGoldens('app', <GoldenScenario>[
    GoldenScenario('application_theme', () {
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) => Scaffold(
              appBar: AppBar(title: const Text('Hacki')),
              body: const CenteredMessageView(
                content:
                    'A Hacker News client.\nStories, discussions, and ideas.',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      return Builder(
        builder: (BuildContext context) => HackiApp(
          savedThemeMode: AdaptiveThemeMode.light,
          blocProviders: <BlocProvider<dynamic>>[
            BlocProvider<PreferenceCubit>.value(
              value: context.read<PreferenceCubit>(),
            ),
          ],
          routerConfig: router,
        ),
      );
    }, covers: <String>{'lib/main.dart#HackiApp'}),
  ]);
}
