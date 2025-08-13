import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';
import 'user_session.dart';

class Task {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final Map<String, dynamic>? user;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.user,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'user': user,
    };
  }
}

class TaskService {
  static String get baseUrl => getBaseUrl();
  
  // Get all tasks (for admin)
  static Future<List<Task>> getAllTasks({String? status}) async {
    if (useMockOnly) {
      return _getMockTasks();
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      String url = '$baseUrl/tasks';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: getHeaders(token: UserSession.instance.token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? body['tasks'] ?? [];
        return data.map((j) => Task.fromJson(j)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock data
      return _getMockTasks();
    }
  }

  // Get tasks for specific user (for employees)
  static Future<List<Task>> getUserTasks(int userId) async {
    if (useMockOnly) {
      return _getMockTasks();
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/user/$userId'),
        headers: getHeaders(token: UserSession.instance.token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? body['tasks'] ?? [];
        return data.map((j) => Task.fromJson(j)).toList();
      } else {
        throw Exception('Failed to load user tasks: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock data
      return _getMockTasks();
    }
  }

  // Get current user's tasks
  static Future<List<Task>> getMyTasks() async {
    if (useMockOnly) {
      return _getMockTasks();
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');
      return await getUserTasks(UserSession.instance.userId!);
    } catch (e) {
      // Fallback to mock data
      return _getMockTasks();
    }
  }

  // Create new task (admin only)
  static Future<Task> createTask({
    required int userId,
    required String title,
    String? description,
    required String status,
    DateTime? dueDate,
  }) async {
    if (useMockOnly) {
      return _createMockTask(userId: userId, title: title, description: description, status: status, dueDate: dueDate);
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: getHeaders(token: UserSession.instance.token),
        body: json.encode({
          'userId': userId,
          'title': title,
          'description': description,
          'status': status,
          'dueDate': dueDate?.toIso8601String(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = json.decode(response.body);
        final data = body['data'] ?? body;
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to create task: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock data
      return _createMockTask(userId: userId, title: title, description: description, status: status, dueDate: dueDate);
    }
  }

  // Update task
  static Future<Task> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? status,
    DateTime? dueDate,
    int? userId,
  }) async {
    if (useMockOnly) {
      return _updateMockTask(taskId: taskId, title: title, description: description, status: status, dueDate: dueDate, userId: userId);
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: getHeaders(token: UserSession.instance.token),
        body: json.encode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          if (userId != null) 'userId': userId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = json.decode(response.body);
        final data = body['data'] ?? body;
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to update task: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock data
      return _updateMockTask(taskId: taskId, title: title, description: description, status: status, dueDate: dueDate, userId: userId);
    }
  }

  // Delete task
  static Future<void> deleteTask(int taskId) async {
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: getHeaders(token: UserSession.instance.token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  // Get task statistics (for admin dashboard)
  static Future<Map<String, dynamic>> getTaskStats() async {
    if (useMockOnly) {
      return _getMockTaskStats();
    }
    
    try {
      if (!UserSession.instance.isLoggedIn) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/stats/overview'),
        headers: getHeaders(token: UserSession.instance.token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load task stats: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock data
      return _getMockTaskStats();
    }
  }

  // Mock data methods
  static List<Task> _getMockTasks() {
    return [
      Task(
        id: 1,
        userId: 2,
        title: 'Complete Frontend Design',
        description: 'Design and implement the user interface',
        status: 'PENDING',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        user: {'name': 'John Doe', 'email': 'john.doe@nishali.com'},
      ),
      Task(
        id: 2,
        userId: 2,
        title: 'Backend API Development',
        description: 'Create RESTful APIs for the application',
        status: 'IN_PROGRESS',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        user: {'name': 'John Doe', 'email': 'john.doe@nishali.com'},
      ),
    ];
  }

  static Task _createMockTask({
    required int userId,
    required String title,
    String? description,
    required String status,
    DateTime? dueDate,
  }) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      user: {'name': 'Employee', 'email': 'employee@nishali.com'},
    );
  }

  static Task _updateMockTask({
    required int taskId,
    String? title,
    String? description,
    String? status,
    DateTime? dueDate,
    int? userId,
  }) {
    // Find the existing task to preserve its data
    final existingTasks = _getMockTasks();
    final existingTask = existingTasks.firstWhere(
      (task) => task.id == taskId,
      orElse: () => Task(
        id: taskId,
        userId: userId ?? 2,
        title: title ?? 'Updated Task',
        description: description,
        status: status ?? 'COMPLETED',
        dueDate: dueDate,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        user: {'name': 'John Doe', 'email': 'john.doe@nishali.com'},
      ),
    );
    
    return Task(
      id: taskId,
      userId: userId ?? existingTask.userId,
      title: title ?? existingTask.title,
      description: description ?? existingTask.description,
      status: status ?? existingTask.status,
      dueDate: dueDate ?? existingTask.dueDate,
      createdAt: existingTask.createdAt,
      user: existingTask.user,
    );
  }

  static Map<String, dynamic> _getMockTaskStats() {
    return {
      'total': 10,
      'pending': 5,
      'inProgress': 3,
      'completed': 2,
    };
  }
} 