import 'package:flutter/material.dart';

/// Global navigator key so code outside the widget tree (e.g. FCM
/// notification-tap handling, which can fire while the app was launched
/// from a terminated state) can still push routes safely.
class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;
}
