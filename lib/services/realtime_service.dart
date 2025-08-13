import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'user_session.dart';
import 'api_base.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _token;

  // Callbacks for different events
  Function(Map<String, dynamic>)? onAttendanceUpdate;
  Function(Map<String, dynamic>)? onTaskUpdate;
  Function(Map<String, dynamic>)? onLeaveRequestUpdate;
  Function(Map<String, dynamic>)? onNotification;
  Function(Map<String, dynamic>)? onAnnouncementCreated;

  // Initialize WebSocket connection
  Future<void> initialize() async {
    try {
      await UserSession.instance.loadUserSession();
      _token = UserSession.instance.token;
      
      if (_token == null) {
        print('❌ No token available for WebSocket connection');
        return;
      }

      _socket = IO.io(getWebSocketBaseUrl(), <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': _token}
      });

      _setupEventListeners();
      _connect();
    } catch (e) {
      print('❌ WebSocket initialization error: $e');
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      print('🔌 WebSocket connected');
      _isConnected = true;
      _authenticate();
    });

    _socket?.onDisconnect((_) {
      print('🔌 WebSocket disconnected');
      _isConnected = false;
    });

    _socket?.onConnectError((error) {
      print('❌ WebSocket connection error: $error');
      _isConnected = false;
    });

    // Handle authentication response
    _socket?.on('authenticated', (data) {
      if (data['success']) {
        print('✅ WebSocket authenticated');
      } else {
        print('❌ WebSocket authentication failed');
      }
    });

    // Handle attendance updates
    _socket?.on('attendance_updated', (data) {
      print('📊 Attendance update received: $data');
      onAttendanceUpdate?.call(data);
    });

    // Handle task updates
    _socket?.on('task_updated', (data) {
      print('📋 Task update received: $data');
      onTaskUpdate?.call(data);
    });

    // Handle leave request updates
    _socket?.on('leave_request_updated', (data) {
      print('🏖️ Leave request update received: $data');
      onLeaveRequestUpdate?.call(data);
    });

    // Handle notifications
    _socket?.on('notification', (data) {
      print('🔔 Notification received: $data');
      onNotification?.call(data);
    });

    // Handle new announcements
    _socket?.on('announcement_created', (data) {
      print('📢 New announcement received: $data');
      onAnnouncementCreated?.call(data);
    });

    // Handle errors
    _socket?.on('error', (data) {
      print('❌ WebSocket error: $data');
    });
  }

  void _connect() {
    _socket?.connect();
  }

  void _authenticate() {
    if (_token != null) {
      _socket?.emit('authenticate', {'token': _token});
    }
  }

  // Send attendance update
  void sendAttendanceUpdate(int userId, String action, String timestamp) {
    if (_isConnected) {
      _socket?.emit('attendance_update', {
        'userId': userId,
        'action': action,
        'timestamp': timestamp
      });
    }
  }

  // Send task update
  void sendTaskUpdate(int taskId, String status, int userId) {
    if (_isConnected) {
      _socket?.emit('task_update', {
        'taskId': taskId,
        'status': status,
        'userId': userId
      });
    }
  }

  // Send leave request update
  void sendLeaveRequestUpdate(int requestId, String status, int userId) {
    if (_isConnected) {
      _socket?.emit('leave_request_update', {
        'requestId': requestId,
        'status': status,
        'userId': userId
      });
    }
  }

  // Send new announcement
  void sendNewAnnouncement(String title, String content, int adminId) {
    if (_isConnected) {
      _socket?.emit('new_announcement', {
        'title': title,
        'content': content,
        'adminId': adminId
      });
    }
  }

  // Disconnect WebSocket
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  // Check connection status
  bool get isConnected => _isConnected;
} 