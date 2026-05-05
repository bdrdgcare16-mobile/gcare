import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance logging helper for API calls and screen performance
class PerformanceLogger {
  static const bool _enabled = kDebugMode;
  
  static void logApiCall({
    required String screen,
    required String endpoint,
    required DateTime startTime,
    required DateTime endTime,
    required int statusCode,
    int? itemCount,
    String? error,
  }) {
    if (!_enabled) return;
    
    final duration = endTime.difference(startTime).inMilliseconds;
    final hasToken = error == null; // Assume token exists if no error
    
    final logEntry = {
      'screen': screen,
      'endpoint': endpoint,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration,
      'statusCode': statusCode,
      'itemCount': itemCount ?? 0,
      'hasToken': hasToken,
      if (error != null) 'error': error,
    };
    
    developer.log(
      'PERF: API Call',
      name: 'Performance',
      time: endTime,
      level: duration > 3000 ? 1000 : (duration > 1000 ? 900 : 800),
      zone: Zone.current,
      error: logEntry,
    );
    
    // Also print for immediate visibility in debug console
    print('=== API PERFORMANCE ===');
    print('Screen: $screen');
    print('Endpoint: $endpoint');
    print('Duration: ${duration}ms');
    print('Status: $statusCode');
    print('Items: ${itemCount ?? 0}');
    print('Token exists: $hasToken');
    if (error != null) print('Error: $error');
    print('========================');
  }
  
  static void logScreenLoad({
    required String screen,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;
    
    final duration = endTime.difference(startTime).inMilliseconds;
    
    final logEntry = {
      'screen': screen,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration,
      if (metadata != null) ...metadata,
    };
    
    developer.log(
      'PERF: Screen Load',
      name: 'Performance',
      time: endTime,
      level: duration > 2000 ? 1000 : (duration > 1000 ? 900 : 800),
      zone: Zone.current,
      error: logEntry,
    );
    
    print('=== SCREEN PERFORMANCE ===');
    print('Screen: $screen');
    print('Load time: ${duration}ms');
    if (metadata != null) {
      metadata.forEach((key, value) => print('$key: $value'));
    }
    print('==========================');
  }
  
  static void logOperation({
    required String operation,
    required String screen,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;
    
    final duration = endTime.difference(startTime).inMilliseconds;
    
    final logEntry = {
      'operation': operation,
      'screen': screen,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration,
      if (metadata != null) ...metadata,
    };
    
    developer.log(
      'PERF: Operation',
      name: 'Performance',
      time: endTime,
      level: duration > 1000 ? 900 : 800,
      zone: Zone.current,
      error: logEntry,
    );
    
    print('=== OPERATION PERFORMANCE ===');
    print('Operation: $operation');
    print('Screen: $screen');
    print('Duration: ${duration}ms');
    if (metadata != null) {
      metadata.forEach((key, value) => print('$key: $value'));
    }
    print('============================');
  }
}

/// Mixin to easily add performance logging to any class
mixin PerformanceTracker {
  DateTime? _operationStart;
  
  void startOperation() {
    _operationStart = DateTime.now();
  }
  
  void endOperation({
    required String operation,
    required String screen,
    Map<String, dynamic>? metadata,
  }) {
    if (_operationStart != null) {
      PerformanceLogger.logOperation(
        operation: operation,
        screen: screen,
        startTime: _operationStart!,
        endTime: DateTime.now(),
        metadata: metadata,
      );
      _operationStart = null;
    }
  }
}
