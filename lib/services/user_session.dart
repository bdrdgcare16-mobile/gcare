import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static UserSession? _instance;
  static UserSession get instance => _instance ??= UserSession._internal();
  
  UserSession._internal();

  Map<String, dynamic>? _currentUser;
  String? _token;

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get token => _token;
  int? get userId => _currentUser?['id'];
  String? get userRole => _currentUser?['role'];
  String? get userName => _currentUser?['name'];
  String? get userEmail => _currentUser?['email'];

  Future<void> setUserSession(Map<String, dynamic> user, String token) async {
    _currentUser = user;
    _token = token;
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user));
    await prefs.setString('auth_token', token);
  }

  Future<void> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_session');
    final tokenStr = prefs.getString('auth_token');
    
    if (userStr != null && tokenStr != null) {
      _currentUser = jsonDecode(userStr);
      _token = tokenStr;
    }
  }

  Future<void> clearUserSession() async {
    _currentUser = null;
    _token = null;
    
    // Clear from local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('auth_token');
  }

  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isAdmin => userRole == 'ADMIN';
  bool get isEmployee => userRole == 'EMPLOYEE';
} 