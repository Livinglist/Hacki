import 'package:flutter/material.dart';
import 'package:hacki/screens/screens.dart';

/// Custom router.
///
/// Handle named routing.
class CustomRouter {
  /// Top level routing.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case HomeScreen.routeName:
        return HomeScreen.route();
      case ItemScreen.routeName:
        return ItemScreen.route(settings.arguments! as ItemScreenArgs);
      case SubmitScreen.routeName:
        return SubmitScreen.route();
      default:
        return _errorRoute();
    }
  }

  /// Nested routing for bottom navigation bar.
  static Route<dynamic> onGenerateNestedRoute(RouteSettings settings) {
    switch (settings.name) {
      case ItemScreen.routeName:
        return ItemScreen.route(settings.arguments! as ItemScreenArgs);
      case SubmitScreen.routeName:
        return SubmitScreen.route();
      default:
        return _errorRoute();
    }
  }

  /// Error route.
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute<dynamic>(
      settings: const RouteSettings(name: '/error'),
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Something went wrong!'),
        ),
      ),
    );
  }
}
