import 'package:flutter/material.dart';

/// Attached to the root [MaterialApp] so code with no [BuildContext] (e.g. the Dio auth
/// interceptor) can still navigate - used to force a return to sign-in on session expiry.
final navigatorKey = GlobalKey<NavigatorState>();

class NavigationService {
  const NavigationService();

  Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<T?> pushReplacement<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushReplacement<T, T>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushAndRemoveUntil<T>(MaterialPageRoute(builder: (_) => screen), (route) => false);
  }

  void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}

const navigationService = NavigationService();
