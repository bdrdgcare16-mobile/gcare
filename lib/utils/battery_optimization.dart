import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;

/// Thin wrapper over the `serv/battery_opt` MethodChannel registered in
/// MainActivity. Returns the OS truth for whether this app is exempted
/// from battery optimization - NOT whether the user once saw a prompt.
class BatteryOptimization {
  BatteryOptimization._();

  static const _channel = MethodChannel('serv/battery_opt');

  /// True only when Android reports the exemption granted. Fails safe to
  /// `false` (i.e. "not exempt, prompt allowed") on any error - the prompt
  /// is non-blocking and optional, so a wrong false is harmless while a
  /// wrong true would silently skip the request.
  static Future<bool> isExempt() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ==
          true;
    } catch (_) {
      return false;
    }
  }
}

/// Pure decision function (unit-testable without platform channels).
/// Prompt only when: Android + not already exempt + never prompted before.
/// Exemption is a convenience for continuous tracking reliability - it is
/// NEVER mandatory for attendance, and the user declining is final (the
/// prompted-once record is set before the intent launches, so a dismissed
/// or cancelled dialog still counts as "prompted").
bool shouldPromptBatteryExemption({
  required bool isAndroid,
  required bool alreadyExempt,
  required bool promptedBefore,
}) {
  return isAndroid && !alreadyExempt && !promptedBefore;
}
