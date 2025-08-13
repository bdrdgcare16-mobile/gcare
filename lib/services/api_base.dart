import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// API Configuration
const String defaultApiBaseUrl = 'http://localhost:8080';
const String webApiBaseUrl = 'http://localhost:8080';
const int apiTimeout = 5000; // 5 seconds timeout for better reliability
const bool useMockOnly = false; // Use real data from database

// Get the appropriate base URL based on platform
String getBaseUrl() {
  if (kIsWeb) {
    return webApiBaseUrl;
  }
  // Android emulator needs to access host via 10.0.2.2
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return defaultApiBaseUrl;
}

// WebSocket base URL helper (same host as HTTP in this app)
String getWebSocketBaseUrl() {
  return getBaseUrl();
}

Map<String, String> getHeaders({String? token}) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Bearer $token',
};

// Enhanced HTTP GET with timeout and error handling
Future<http.Response> httpGetWithTimeout(String url, {Map<String, String>? headers}) async {
  try {
    return await http.get(Uri.parse(url), headers: headers).timeout(
      
      Duration(milliseconds: apiTimeout),
      onTimeout: () {
        throw Exception('Request timeout - server not responding');
      },
    );
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

// Enhanced HTTP POST with timeout and error handling
Future<http.Response> httpPostWithTimeout(String url, {Map<String, String>? headers, Object? body}) async {
  try {
    return await http.post(Uri.parse(url), headers: headers, body: body).timeout(
      Duration(milliseconds: apiTimeout),
      onTimeout: () {
        throw Exception('Request timeout - server not responding');
      },
    );
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

// Enhanced HTTP PUT with timeout and error handling
Future<http.Response> httpPutWithTimeout(String url, {Map<String, String>? headers, Object? body}) async {
  try {
    return await http.put(Uri.parse(url), headers: headers, body: body).timeout(
      Duration(milliseconds: apiTimeout),
      onTimeout: () {
        throw Exception('Request timeout - server not responding');
      },
    );
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

// Enhanced HTTP DELETE with timeout and error handling
Future<http.Response> httpDeleteWithTimeout(String url, {Map<String, String>? headers}) async {
  try {
    return await http.delete(Uri.parse(url), headers: headers).timeout(
      Duration(milliseconds: apiTimeout),
      onTimeout: () {
        throw Exception('Request timeout - server not responding');
      },
    );
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

// Helper function to handle API responses
Map<String, dynamic> handleApiResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return json.decode(response.body);
  } else {
    throw Exception('API Error: ${response.statusCode} - ${response.body}');
  }
} 