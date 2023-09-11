import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';

final GoRouter router = GoRouter(
  observers: <NavigatorObserver>[
    RouteObserver<ModalRoute<dynamic>>(),
  ],
  initialLocation: HomeScreen.routeName,
  routes: <RouteBase>[
    GoRoute(
      path: HomeScreen.routeName,
      builder: (_, __) => const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: ItemScreen.routeName,
          builder: (_, GoRouterState state) {
            final ItemScreenArgs? args = state.extra as ItemScreenArgs?;
            if (args == null) {
              throw GoError("args can't be null");
            }
            return ItemScreen.phone(args);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/${ItemScreen.routeName}',
      builder: (_, GoRouterState state) {
        final ItemScreenArgs? args = state.extra as ItemScreenArgs?;
        if (args == null) {
          throw GoError("args can't be null");
        }
        return ItemScreen.phone(args);
      },
    ),
    GoRoute(
      path: '/${SubmitScreen.routeName}',
      builder: (_, __) => BlocProvider<SubmitCubit>(
        create: (_) => SubmitCubit(),
        child: const SubmitScreen(),
      ),
    ),
    GoRoute(
      path: '/${QrCodeScannerScreen.routeName}',
      builder: (_, __) => const QrCodeScannerScreen(),
    ),
    GoRoute(
      path: '/${QrCodeViewScreen.routeName}',
      builder: (_, GoRouterState state) {
        final String? data = state.extra as String?;
        if (data == null) {
          throw GoError("data can't be null");
        }
        return QrCodeViewScreen(
          data: data,
        );
      },
    ),
    GoRoute(
      path: '/${WebViewScreen.routeName}',
      builder: (_, GoRouterState state) {
        final String? link = state.extra as String?;
        if (link == null) {
          throw GoError("link can't be null");
        }
        return WebViewScreen(
          url: link,
        );
      },
    ),
  ],
);
