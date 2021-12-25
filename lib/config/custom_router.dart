import 'package:flutter/material.dart';
import 'package:hacki/screens/screens.dart';

/// Custom router.
///
/// Handle named routing.
class CustomRouter {
  /// Top level routing.
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case HomeScreen.routeName:
        return HomeScreen.route();
      case StoryScreen.routeName:
        return StoryScreen.route(settings.arguments! as StoryScreenArgs);
      default:
        return _errorRoute();
    }
  }

  /// Nested routing for bottom navigation bar.
  static Route onGenerateNestedRoute(RouteSettings settings) {
    switch (settings.name) {
      case HomeScreen.routeName:
        return HomeScreen.route();
      default:
        return _errorRoute();
    }
  }

  /// Error route.
  static Route _errorRoute() {
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
