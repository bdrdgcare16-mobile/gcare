import 'dart:async';
import 'package:flutter/material.dart';

/// Centralized service for attendance timing logic
/// Ensures consistency across all attendance modules
class AttendanceTimeService {
  static const Duration _apiTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  // Business logic constants
  static const int _lateGraceMinutes = 5;
  static const int _halfDayThresholdMinutes = 240; // 4 hours
  static const int _earlyCheckoutGraceMinutes = 5;
  
  static final AttendanceTimeService _instance = AttendanceTimeService._internal();
  factory AttendanceTimeService() => _instance;
  AttendanceTimeService._internal();
  
  /// Structured logging
  void _log(String level, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    print('[$timestamp] [$level] [AttendanceTimeService] $message$contextStr');
  }
  
  void logInfo(String message, {Map<String, dynamic>? context}) => _log('INFO', message, context: context);
  void logError(String message, {Map<String, dynamic>? context}) => _log('ERROR', message, context: context);
  void logWarning(String message, {Map<String, dynamic>? context}) => _log('WARNING', message, context: context);
  void logDebug(String message, {Map<String, dynamic>? context}) => _log('DEBUG', message, context: context);
  
  /// Validates shift data integrity
  bool validateShiftData(Map<String, dynamic> shiftData) {
    try {
      final startTime = shiftData['startTime']?.toString().trim() ?? '';
      final endTime = shiftData['endTime']?.toString().trim() ?? '';
      final shiftName = shiftData['shiftname']?.toString().trim() ?? '';
      
      if (startTime.isEmpty || endTime.isEmpty || shiftName.isEmpty) {
        logError('Invalid shift data', context: {
          'startTime': startTime,
          'endTime': endTime,
          'shiftName': shiftName,
        });
        return false;
      }
      
      // Validate time format
      if (!_isValidTimeFormat(startTime) || !_isValidTimeFormat(endTime)) {
        logError('Invalid time format in shift data', context: {
          'startTime': startTime,
          'endTime': endTime,
        });
        return false;
      }
      
      return true;
    } catch (e) {
      logError('Exception validating shift data', context: {'error': e.toString()});
      return false;
    }
  }
  
  /// Validates time format (HH:MM)
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^(\d{1,2}):(\d{2})$');
    final match = regex.firstMatch(time);
    if (match == null) return false;
    
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    
    return hour != null && minute != null && 
           hour >= 0 && hour <= 23 && 
           minute >= 0 && minute <= 59;
  }
  
  /// Parses time string to TimeOfDay with validation
  TimeOfDay? parseTime(String timeString) {
    if (!_isValidTimeFormat(timeString)) {
      logError('Invalid time format for parsing', context: {'timeString': timeString});
      return null;
    }
    
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      logError('Exception parsing time', context: {
        'timeString': timeString,
        'error': e.toString(),
      });
      return null;
    }
  }
  
  /// Determines if check-in is late based on shift start time
  CheckInResult determineCheckInStatus({
    required TimeOfDay shiftStart,
    required DateTime checkInTime,
    required String employeeId,
    required String shiftName,
  }) {
    try {
      final now = DateTime.now();
      final shiftStartDateTime = DateTime(
        now.year, now.month, now.day, 
        shiftStart.hour, shiftStart.minute,
      );
      
      final graceEndTime = shiftStartDateTime.add(Duration(minutes: _lateGraceMinutes));
      final isLate = checkInTime.isAfter(graceEndTime);
      
      final result = CheckInResult(
        isLate: isLate,
        checkInTime: checkInTime,
        shiftStartTime: shiftStartDateTime,
        graceEndTime: graceEndTime,
        graceMinutes: _lateGraceMinutes,
        employeeId: employeeId,
        shiftName: shiftName,
      );
      
      logInfo('Check-in status determined', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'isLate': isLate,
        'checkInTime': checkInTime.toIso8601String(),
        'shiftStart': shiftStartDateTime.toIso8601String(),
        'graceEnd': graceEndTime.toIso8601String(),
      });
      
      return result;
    } catch (e) {
      logError('Exception determining check-in status', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'error': e.toString(),
      });
      return CheckInResult.error(employeeId, shiftName, e.toString());
    }
  }
  
  /// Determines if check-out is early or late
  CheckOutResult determineCheckOutStatus({
    required TimeOfDay shiftEnd,
    required DateTime checkOutTime,
    required String employeeId,
    required String shiftName,
  }) {
    try {
      final now = DateTime.now();
      var shiftEndDateTime = DateTime(
        now.year, now.month, now.day,
        shiftEnd.hour, shiftEnd.minute,
      );
      
      // Handle overnight shifts
      if (shiftEndDateTime.isBefore(DateTime(now.year, now.month, now.day, 0, 0))) {
        shiftEndDateTime = shiftEndDateTime.add(const Duration(days: 1));
      }
      
      final graceEndTime = shiftEndDateTime.add(Duration(minutes: _earlyCheckoutGraceMinutes));
      final isEarly = checkOutTime.isBefore(shiftEndDateTime);
      final isLate = checkOutTime.isAfter(graceEndTime);
      
      final result = CheckOutResult(
        isEarly: isEarly,
        isLate: isLate,
        checkOutTime: checkOutTime,
        shiftEndTime: shiftEndDateTime,
        graceEndTime: graceEndTime,
        graceMinutes: _earlyCheckoutGraceMinutes,
        employeeId: employeeId,
        shiftName: shiftName,
      );
      
      logInfo('Check-out status determined', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'isEarly': isEarly,
        'isLate': isLate,
        'checkOutTime': checkOutTime.toIso8601String(),
        'shiftEnd': shiftEndDateTime.toIso8601String(),
        'graceEnd': graceEndTime.toIso8601String(),
      });
      
      return result;
    } catch (e) {
      logError('Exception determining check-out status', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'error': e.toString(),
      });
      return CheckOutResult.error(employeeId, shiftName, e.toString());
    }
  }
  
  /// Determines if attendance qualifies as half-day
  HalfDayResult determineHalfDayStatus({
    required DateTime checkInTime,
    required TimeOfDay shiftStart,
    required String employeeId,
    required String shiftName,
  }) {
    try {
      final now = DateTime.now();
      final shiftStartDateTime = DateTime(
        now.year, now.month, now.day,
        shiftStart.hour, shiftStart.minute,
      );
      
      final lateMinutes = checkInTime.difference(shiftStartDateTime).inMinutes;
      final isHalfDay = lateMinutes >= _halfDayThresholdMinutes;
      
      final result = HalfDayResult(
        isHalfDay: isHalfDay,
        lateMinutes: lateMinutes,
        thresholdMinutes: _halfDayThresholdMinutes,
        checkInTime: checkInTime,
        shiftStartTime: shiftStartDateTime,
        employeeId: employeeId,
        shiftName: shiftName,
      );
      
      logInfo('Half-day status determined', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'isHalfDay': isHalfDay,
        'lateMinutes': lateMinutes,
        'threshold': _halfDayThresholdMinutes,
      });
      
      return result;
    } catch (e) {
      logError('Exception determining half-day status', context: {
        'employeeId': employeeId,
        'shiftName': shiftName,
        'error': e.toString(),
      });
      return HalfDayResult.error(employeeId, shiftName, e.toString());
    }
  }
  
  /// API call with retry logic
  Future<Map<String, dynamic>?> callApiWithRetry(
    String url,
    Map<String, String> headers, {
    int? maxRetries,
    Duration? timeout,
    Duration? retryDelay,
  }) async {
    final retries = maxRetries ?? _maxRetries;
    final apiTimeout = timeout ?? _apiTimeout;
    final delay = retryDelay ?? _retryDelay;
    
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        logInfo('API call attempt', context: {
          'url': url,
          'attempt': attempt,
          'maxRetries': retries,
        });
        
        // This would be implemented with actual HTTP client
        // For now, returning null as placeholder
        throw UnimplementedError('HTTP client not implemented in this service');
        
      } catch (e) {
        logError('API call failed', context: {
          'url': url,
          'attempt': attempt,
          'error': e.toString(),
        });
        
        if (attempt == retries) {
          logError('API call failed after all retries', context: {
            'url': url,
            'totalAttempts': retries,
            'finalError': e.toString(),
          });
          return null;
        }
        
        // Wait before retry
        await Future.delayed(delay * attempt); // Exponential backoff
      }
    }
    
    return null;
  }
}

/// Result classes for better type safety
class CheckInResult {
  final bool isLate;
  final DateTime checkInTime;
  final DateTime shiftStartTime;
  final DateTime graceEndTime;
  final int graceMinutes;
  final String employeeId;
  final String shiftName;
  final String? error;
  
  CheckInResult({
    required this.isLate,
    required this.checkInTime,
    required this.shiftStartTime,
    required this.graceEndTime,
    required this.graceMinutes,
    required this.employeeId,
    required this.shiftName,
  }) : error = null;
  
  CheckInResult.error(this.employeeId, this.shiftName, this.error)
      : isLate = false,
        checkInTime = DateTime.now(),
        shiftStartTime = DateTime.now(),
        graceEndTime = DateTime.now(),
        graceMinutes = 0;
  
  bool get hasError => error != null;
}

class CheckOutResult {
  final bool isEarly;
  final bool isLate;
  final DateTime checkOutTime;
  final DateTime shiftEndTime;
  final DateTime graceEndTime;
  final int graceMinutes;
  final String employeeId;
  final String shiftName;
  final String? error;
  
  CheckOutResult({
    required this.isEarly,
    required this.isLate,
    required this.checkOutTime,
    required this.shiftEndTime,
    required this.graceEndTime,
    required this.graceMinutes,
    required this.employeeId,
    required this.shiftName,
  }) : error = null;
  
  CheckOutResult.error(this.employeeId, this.shiftName, this.error)
      : isEarly = false,
        isLate = false,
        checkOutTime = DateTime.now(),
        shiftEndTime = DateTime.now(),
        graceEndTime = DateTime.now(),
        graceMinutes = 0;
  
  bool get hasError => error != null;
}

class HalfDayResult {
  final bool isHalfDay;
  final int lateMinutes;
  final int thresholdMinutes;
  final DateTime checkInTime;
  final DateTime shiftStartTime;
  final String employeeId;
  final String shiftName;
  final String? error;
  
  HalfDayResult({
    required this.isHalfDay,
    required this.lateMinutes,
    required this.thresholdMinutes,
    required this.checkInTime,
    required this.shiftStartTime,
    required this.employeeId,
    required this.shiftName,
  }) : error = null;
  
  HalfDayResult.error(this.employeeId, this.shiftName, this.error)
      : isHalfDay = false,
        lateMinutes = 0,
        thresholdMinutes = 0,
        checkInTime = DateTime.now(),
        shiftStartTime = DateTime.now();
  
  bool get hasError => error != null;
}
