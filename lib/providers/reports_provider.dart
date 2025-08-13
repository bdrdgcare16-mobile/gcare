import 'package:flutter/foundation.dart';
import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  
  // Report data
  Map<String, dynamic>? _attendanceReport;
  Map<String, dynamic>? _payrollReport;
  Map<String, dynamic>? _performanceReport;
  Map<String, dynamic>? _leaveReport;
  Map<String, dynamic>? _dashboardSummary;
  
  // Loading states
  bool _isLoadingAttendance = false;
  bool _isLoadingPayroll = false;
  bool _isLoadingPerformance = false;
  bool _isLoadingLeave = false;
  bool _isLoadingDashboard = false;
  
  // Error states
  String? _attendanceError;
  String? _payrollError;
  String? _performanceError;
  String? _leaveError;
  String? _dashboardError;

  // Getters
  Map<String, dynamic>? get attendanceReport => _attendanceReport;
  Map<String, dynamic>? get payrollReport => _payrollReport;
  Map<String, dynamic>? get performanceReport => _performanceReport;
  Map<String, dynamic>? get leaveReport => _leaveReport;
  Map<String, dynamic>? get dashboardSummary => _dashboardSummary;
  
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingPayroll => _isLoadingPayroll;
  bool get isLoadingPerformance => _isLoadingPerformance;
  bool get isLoadingLeave => _isLoadingLeave;
  bool get isLoadingDashboard => _isLoadingDashboard;
  
  String? get attendanceError => _attendanceError;
  String? get payrollError => _payrollError;
  String? get performanceError => _performanceError;
  String? get leaveError => _leaveError;
  String? get dashboardError => _dashboardError;

  // Load attendance report
  Future<void> loadAttendanceReport({
    int? userId,
    int? month,
    int? year,
    String? type = 'monthly',
  }) async {
    _isLoadingAttendance = true;
    _attendanceError = null;
    notifyListeners();

    try {
      _attendanceReport = await _reportsService.getAttendanceReport(
        userId: userId,
        month: month,
        year: year,
        type: type,
      );
    } catch (e) {
      _attendanceError = e.toString();
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  // Load payroll report
  Future<void> loadPayrollReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    _isLoadingPayroll = true;
    _payrollError = null;
    notifyListeners();

    try {
      _payrollReport = await _reportsService.getPayrollReport(
        userId: userId,
        month: month,
        year: year,
      );
    } catch (e) {
      _payrollError = e.toString();
    } finally {
      _isLoadingPayroll = false;
      notifyListeners();
    }
  }

  // Load performance report
  Future<void> loadPerformanceReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    _isLoadingPerformance = true;
    _performanceError = null;
    notifyListeners();

    try {
      _performanceReport = await _reportsService.getPerformanceReport(
        userId: userId,
        month: month,
        year: year,
      );
    } catch (e) {
      _performanceError = e.toString();
    } finally {
      _isLoadingPerformance = false;
      notifyListeners();
    }
  }

  // Load leave report
  Future<void> loadLeaveReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    _isLoadingLeave = true;
    _leaveError = null;
    notifyListeners();

    try {
      _leaveReport = await _reportsService.getLeaveReport(
        userId: userId,
        month: month,
        year: year,
      );
    } catch (e) {
      _leaveError = e.toString();
    } finally {
      _isLoadingLeave = false;
      notifyListeners();
    }
  }

  // Load dashboard summary
  Future<void> loadDashboardSummary() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      _dashboardSummary = await _reportsService.getDashboardSummary();
    } catch (e) {
      _dashboardError = e.toString();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  // Load all reports
  Future<void> loadAllReports({
    int? userId,
    int? month,
    int? year,
  }) async {
    await Future.wait([
      loadAttendanceReport(userId: userId, month: month, year: year),
      loadPayrollReport(userId: userId, month: month, year: year),
      loadPerformanceReport(userId: userId, month: month, year: year),
      loadLeaveReport(userId: userId, month: month, year: year),
      loadDashboardSummary(),
    ]);
  }

  // Clear all reports
  void clearReports() {
    _attendanceReport = null;
    _payrollReport = null;
    _performanceReport = null;
    _leaveReport = null;
    _dashboardSummary = null;
    
    _attendanceError = null;
    _payrollError = null;
    _performanceError = null;
    _leaveError = null;
    _dashboardError = null;
    
    notifyListeners();
  }

  // Get attendance statistics
  Map<String, dynamic>? get attendanceStats {
    return _attendanceReport?['statistics'];
  }

  // Get payroll statistics
  Map<String, dynamic>? get payrollStats {
    return _payrollReport?['statistics'];
  }

  // Get performance metrics
  Map<String, dynamic>? get performanceMetrics {
    return _performanceReport?['performance'];
  }

  // Get leave statistics
  Map<String, dynamic>? get leaveStats {
    return _leaveReport?['statistics'];
  }

  // Get dashboard summary data
  Map<String, dynamic>? get dashboardData {
    return _dashboardSummary?['summary'];
  }

  // Check if any report is loading
  bool get isAnyLoading {
    return _isLoadingAttendance || 
           _isLoadingPayroll || 
           _isLoadingPerformance || 
           _isLoadingLeave || 
           _isLoadingDashboard;
  }

  // Check if any report has error
  bool get hasAnyError {
    return _attendanceError != null || 
           _payrollError != null || 
           _performanceError != null || 
           _leaveError != null || 
           _dashboardError != null;
  }
} 