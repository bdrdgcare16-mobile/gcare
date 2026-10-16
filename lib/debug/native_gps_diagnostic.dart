import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// TEMPORARY DIAGNOSTIC ONLY.
///
/// Calls the Android Fused Location Provider directly (PRIORITY_HIGH_ACCURACY,
/// the same priority geolocator_android requests for
/// LocationAccuracy.bestForNavigation) via [NativeGpsDiagnostic.kt], so its
/// result can be compared against Geolocator's result on the same device
/// under the same conditions.
///
/// Not wired into check-in/check-out or any production flow. Debug builds
/// and Android only; a no-op everywhere else.
class NativeGpsDiagnostic {
  NativeGpsDiagnostic._();

  static const MethodChannel _channel =
      MethodChannel('serv_app/native_gps_diagnostic');

  static bool get isSupported => !kIsWeb && Platform.isAndroid && kDebugMode;

  /// Returns a map shaped like:
  /// {
  ///   'fused': {latitude, longitude, accuracy, altitude, speed, provider,
  ///             timestampMs, timestampIso, isMocked} | null,
  ///   'gpsProviderLastKnown': same shape | null,
  ///   'capturedAtMs': int,
  /// }
  /// or null if unsupported or the call failed.
  static Future<Map<String, dynamic>?> fusedLocationOnce() async {
    if (!isSupported) return null;
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('fusedLocationOnce');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[NativeGpsDiagnostic] platform error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[NativeGpsDiagnostic] error: $e');
      return null;
    }
  }

  /// Fresh, FLP-bypassing capture straight from LocationManager.GPS_PROVIDER
  /// + GnssStatus. Time-bounded natively (~25s) and cancellable - call
  /// [cancelRawGpsCapture] if the caller gives up early (e.g. widget
  /// disposed) so the native listener is torn down immediately rather than
  /// waiting out the timeout.
  ///
  /// Returns a map shaped like:
  /// {
  ///   'gpsProviderEnabled': bool,
  ///   'satelliteCount': int,
  ///   'satellitesUsedInFix': int,
  ///   'timeToFirstFixMs': int | null,
  ///   'captureDurationMs': int,
  ///   'fixState': 'gps_provider_disabled' | 'no_satellites_detected' |
  ///               'satellites_visible_no_fix' |
  ///               'satellites_used_but_no_location_yet' |
  ///               'gps_fix_poor_accuracy' | 'gps_fix_accurate',
  ///   'fix': {latitude, longitude, accuracy, altitude, speed, provider,
  ///           timestampMs, timestampIso, isMocked} | null,
  /// }
  /// or null if unsupported or the call failed/was cancelled.
  static Future<Map<String, dynamic>?> rawGpsProviderCapture() async {
    if (!isSupported) return null;
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('rawGpsProviderCapture');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[NativeGpsDiagnostic] raw capture platform error: '
          '${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[NativeGpsDiagnostic] raw capture error: $e');
      return null;
    }
  }

  /// Cancels an in-flight [rawGpsProviderCapture], if any. Safe to call
  /// even when no capture is running.
  static Future<void> cancelRawGpsCapture() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelRawGpsCapture');
    } catch (e) {
      debugPrint('[NativeGpsDiagnostic] cancelRawGpsCapture error: $e');
    }
  }
}
