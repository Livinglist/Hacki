import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/item/item.dart';
import 'package:hacki/repositories/hacker_news_repository.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/styles/dimens.dart';
import 'package:material_ui/material_ui.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Map<int, Future<Item?>> _deepLinkItemFutures = <int, Future<Item?>>{};

Page<dynamic> _itemScreenPageBuilder(
  BuildContext context,
  GoRouterState state,
) {
  final ItemScreenArgs? args = state.extra as ItemScreenArgs?;
  if (args != null) {
    return MaterialPage<void>(child: ItemScreen.phone(args));
  }

  final int? itemId = state.uri.queryParameters['id']?.itemId;
  if (itemId == null) {
    throw GoError("item args or item id can't be null");
  }

  return MaterialPage<void>(
    child: FutureBuilder<Item?>(
      future: _deepLinkItemFutures.putIfAbsent(
        itemId,
        () => locator.get<HackerNewsRepository>().fetchItem(id: itemId),
      ),
      builder: (BuildContext context, AsyncSnapshot<Item?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(strokeWidth: Dimens.pt2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(body: Center(child: Text(Constants.errorMessage)));
        }

        return ItemScreen.phone(
          ItemScreenArgs(item: snapshot.data!),
          showBackButton: true,
        );
      },
    ),
  );
}

const MethodChannel _iosDeepLinkChannel = MethodChannel('hacki.deep_link');

String? itemLocationFromDeepLink(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }

  final bool isItemPath =
      uri.path == '/${ItemScreen.routeName}' || uri.path == ItemScreen.routeName;
  if (!isItemPath) {
    return null;
  }

  final String? id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) {
    return null;
  }

  return '/${ItemScreen.routeName}?id=$id';
}

Future<void> applyIosLaunchDeepLink() async {
  if (!Platform.isIOS) {
    return;
  }

  final String? url = await _iosDeepLinkChannel.invokeMethod<String>(
    'getLaunchUrl',
  );
  if (url == null) {
    return;
  }

  final String? location = itemLocationFromDeepLink(url);
  if (location == null) {
    return;
  }

  final Uri current = router.state.uri;
  final Uri target = Uri.parse(location);
  if (current.path == target.path &&
      current.queryParameters['id'] == target.queryParameters['id']) {
    return;
  }

  router.go(location);
}

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  observers: <NavigatorObserver>[
    locator.get<RouteObserver<ModalRoute<dynamic>>>(),
  ],
  routes: <RouteBase>[
    GoRoute(
      path: '/${ItemScreen.routeName}/${SettingsScreen.routeName}',
      pageBuilder: (_, __) => const MaterialPage<void>(child: SettingsScreen()),
    ),

    ///
    /// This is so that Android user deep linked to Hacki can go back to the
    /// previous app by tapping on the back button.
    ///
    if (Platform.isAndroid)
      GoRoute(
        path: '/${ItemScreen.routeName}',
        pageBuilder: _itemScreenPageBuilder,
      ),

    GoRoute(
      path: HomeScreen.routeName,
      pageBuilder: (_, __) => const MaterialPage<void>(child: HomeScreen()),
      routes: <RouteBase>[
        GoRoute(
          path: ItemScreen.routeName,
          pageBuilder: _itemScreenPageBuilder,
        ),
        GoRoute(
          path: ShareScreen.routeName,
          pageBuilder: (_, GoRouterState state) {
            final ShareScreenArgs? args = state.extra as ShareScreenArgs?;
            if (args == null) {
              throw GoError("args can't be null");
            }
            return MaterialPage<void>(child: ShareScreen(args));
          },
        ),
        GoRoute(
          path: LogsScreen.routeName,
          pageBuilder: (_, __) => const MaterialPage<void>(child: LogsScreen()),
        ),
        GoRoute(
          path: WebViewScreen.routeName,
          pageBuilder: (_, GoRouterState state) {
            final String? link = state.extra as String?;
            if (link == null) {
              throw GoError("link can't be null");
            }
            return MaterialPage<void>(child: WebViewScreen(url: link));
          },
        ),
        GoRoute(
          path: SubmitScreen.routeName,
          pageBuilder: (_, __) => MaterialPage<void>(
            child: BlocProvider<SubmitCubit>(
              create: (_) => SubmitCubit(),
              child: const SubmitScreen(),
            ),
          ),
        ),
        GoRoute(
          path: QrCodeScannerScreen.routeName,
          pageBuilder: (_, __) =>
              const MaterialPage<void>(child: QrCodeScannerScreen()),
        ),
        GoRoute(
          path: QrCodeViewScreen.routeName,
          pageBuilder: (_, GoRouterState state) {
            final String? data = state.extra as String?;
            if (data == null) {
              throw GoError("data can't be null");
            }
            return MaterialPage<void>(child: QrCodeViewScreen(data: data));
          },
        ),
      ],
    ),
  ],
);
