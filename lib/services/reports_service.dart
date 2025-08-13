import 'api_base.dart';
import 'user_session.dart';

class ReportsService {
  static String get _baseUrl => getBaseUrl();

  // Get attendance report
  Future<Map<String, dynamic>> getAttendanceReport({
    int? userId,
    int? month,
    int? year,
    String? type = 'monthly',
  }) async {
    try {
      final token = UserSession.instance.token;
      final queryParams = <String, String>{};
      
      if (userId != null) queryParams['userId'] = userId.toString();
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$_baseUrl/reports/attendance').replace(queryParameters: queryParams);
      
      final response = await httpGetWithTimeout(
        uri.toString(),
        headers: getHeaders(token: token),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('❌ Attendance report error: $e');
      return _mockAttendanceReport();
    }
  }

  // Get payroll report
  Future<Map<String, dynamic>> getPayrollReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    try {
      final token = UserSession.instance.token;
      final queryParams = <String, String>{};
      
      if (userId != null) queryParams['userId'] = userId.toString();
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$_baseUrl/reports/payroll').replace(queryParameters: queryParams);
      
      final response = await httpGetWithTimeout(
        uri.toString(),
        headers: getHeaders(token: token),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('❌ Payroll report error: $e');
      return _mockPayrollReport();
    }
  }

  // Get performance report
  Future<Map<String, dynamic>> getPerformanceReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    try {
      final token = UserSession.instance.token;
      final queryParams = <String, String>{};
      
      if (userId != null) queryParams['userId'] = userId.toString();
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$_baseUrl/reports/performance').replace(queryParameters: queryParams);
      
      final response = await httpGetWithTimeout(
        uri.toString(),
        headers: getHeaders(token: token),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('❌ Performance report error: $e');
      return _mockPerformanceReport();
    }
  }

  // Get leave report
  Future<Map<String, dynamic>> getLeaveReport({
    int? userId,
    int? month,
    int? year,
  }) async {
    try {
      final token = UserSession.instance.token;
      final queryParams = <String, String>{};
      
      if (userId != null) queryParams['userId'] = userId.toString();
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$_baseUrl/reports/leave').replace(queryParameters: queryParams);
      
      final response = await httpGetWithTimeout(
        uri.toString(),
        headers: getHeaders(token: token),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('❌ Leave report error: $e');
      return _mockLeaveReport();
    }
  }

  // Get dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final token = UserSession.instance.token;
      
      final response = await httpGetWithTimeout(
        '$_baseUrl/reports/dashboard',
        headers: getHeaders(token: token),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('❌ Dashboard summary error: $e');
      return _mockDashboardSummary();
    }
  }

  // Mock data fallbacks
  Map<String, dynamic> _mockAttendanceReport() {
    return {
      'attendance': [
        {
          'id': 1,
          'userId': 1,
          'date': '2024-01-15',
          'checkIn': '09:00:00',
          'checkOut': '17:00:00',
          'status': 'Present',
          'user': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}
        }
      ],
      'statistics': {
        'totalDays': 22,
        'presentDays': 20,
        'absentDays': 1,
        'lateDays': 1,
        'attendanceRate': 90.91
      },
      'period': {
        'startDate': '2024-01-01',
        'endDate': '2024-01-31',
        'type': 'monthly'
      }
    };
  }

  Map<String, dynamic> _mockPayrollReport() {
    return {
      'payrolls': [
        {
          'id': 1,
          'userId': 1,
          'month': 1,
          'year': 2024,
          'amount': 5000.0,
          'user': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}
        }
      ],
      'statistics': {
        'totalEmployees': 10,
        'totalPayroll': 50000.0,
        'averageSalary': 5000.0,
        'highestSalary': 8000.0,
        'lowestSalary': 3000.0
      },
      'period': {
        'month': 1,
        'year': 2024
      }
    };
  }

  Map<String, dynamic> _mockPerformanceReport() {
    return {
      'tasks': [
        {
          'id': 1,
          'title': 'Complete Project A',
          'status': 'Completed',
          'user': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}
        }
      ],
      'attendance': [
        {
          'id': 1,
          'status': 'Present',
          'user': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}
        }
      ],
      'performance': {
        'taskMetrics': {
          'totalTasks': 10,
          'completedTasks': 8,
          'pendingTasks': 1,
          'inProgressTasks': 1,
          'taskCompletionRate': 80.0
        },
        'attendanceMetrics': {
          'totalDays': 22,
          'presentDays': 20,
          'attendanceRate': 90.91
        },
        'overallScore': 85.46
      },
      'period': {
        'startDate': '2024-01-01',
        'endDate': '2024-01-31'
      }
    };
  }

  Map<String, dynamic> _mockLeaveReport() {
    return {
      'leaveRequests': [
        {
          'id': 1,
          'startDate': '2024-01-20',
          'endDate': '2024-01-22',
          'status': 'Approved',
          'user': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
          'leaveType': {'name': 'Annual Leave'}
        }
      ],
      'statistics': {
        'totalRequests': 5,
        'approvedRequests': 4,
        'pendingRequests': 1,
        'rejectedRequests': 0,
        'approvalRate': 80.0
      },
      'leaveTypeStats': {
        'Annual Leave': {'count': 3, 'approved': 2, 'pending': 1, 'rejected': 0},
        'Sick Leave': {'count': 2, 'approved': 2, 'pending': 0, 'rejected': 0}
      },
      'period': {
        'startDate': '2024-01-01',
        'endDate': '2024-01-31'
      }
    };
  }

  Map<String, dynamic> _mockDashboardSummary() {
    return {
      'summary': {
        'totalEmployees': 25,
        'activeEmployees': 23,
        'todayAttendance': 20,
        'pendingLeaves': 3,
        'totalTasks': 45,
        'completedTasks': 38,
        'totalPayroll': 125000.0
      },
      'period': {
        'currentMonth': 'January 2024',
        'today': '2024-01-15'
      }
    };
  }
} 