import 'dart:convert';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart'
    as html; // token from localStorage on web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// You keep a local list in globals_page.dart; we leave it untouched
import 'package:serv_app/features/admin/globals_page.dart';
import 'package:serv_app/services/api_service.dart';

import 'package:serv_app/config/api_config.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF6A1B9A);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

final String apiBase = ApiConfig.baseUrl;

class LeaveFormPage extends StatefulWidget {
  const LeaveFormPage({super.key});

  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _formKey = GlobalKey<FormState>();

  final typeCtrl = TextEditingController();
  final shiftCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final daysCtrl = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  bool _isEditMode = false;
  String? _editingId;
  bool _initializedFromArgs = false;

  // Auth state variables
  String? _token;
  String? _role;
  bool _loadingAuth = true;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      _initializedFromArgs = true;
      _initializeFromRouteArgs();
    }
  }

  @override
  void dispose() {
    typeCtrl.dispose();
    shiftCtrl.dispose();
    fromCtrl.dispose();
    toCtrl.dispose();
    daysCtrl.dispose();
    super.dispose();
  }

  void _initializeFromRouteArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final id = args['id']?.toString();
      if (id != null && id.isNotEmpty) {
        _isEditMode = true;
        _editingId = id;
        typeCtrl.text = args['type']?.toString() ?? '';
        shiftCtrl.text = args['shift']?.toString() ?? '';
        fromCtrl.text = args['fromDate']?.toString() ?? '';
        toCtrl.text = args['toDate']?.toString() ?? '';
        daysCtrl.text = args['allowedDays']?.toString() ?? '';

        fromDate = _parseDateString(fromCtrl.text);
        toDate = _parseDateString(toCtrl.text);
      }
    }
  }

  DateTime? _parseDateString(String value) {
    try {
      return DateFormat('dd-MM-yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load token from SharedPreferences
      final tokenKeys = ['jwt', 'token', 'access_token', 'auth_token'];
      for (final key in tokenKeys) {
        final token = prefs.getString(key);
        if (token != null && token.isNotEmpty) {
          _token = token;
          break;
        }
      }

      // Load role from SharedPreferences
      _role = prefs.getString('role');

      // If role is null, try to decode from JWT payload
      if (_role == null && _token != null) {
        try {
          final parts = _token!.split('.');
          if (parts.length == 3) {
            final payload = jsonDecode(
              utf8.decode(base64.decode(base64.normalize(parts[1])))
            );
            _role = payload['role']?.toString();
          }
        } catch (e) {
          print('JWT parse error: $e');
        }
      }

      print('SHARED PREF TOKEN: $_token');
      print('SHARED PREF ROLE: $_role');
      print('ADMIN CHECK FINAL: ${_isAdmin()}');

      setState(() {
        _loadingAuth = false;
      });
    } catch (e) {
      print('Error loading auth data: $e');
      setState(() {
        _loadingAuth = false;
      });
    }
  }

  String? _getToken() {
    final keys = ['jwt', 'token', 'access_token', 'auth_token'];
    for (final k in keys) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  String? _getUserRole() {
  return _role;
}

  bool _isAdmin() {
  final role = _role?.trim().toLowerCase();
  return role != null && role.contains('admin');
}

  Future<void> _selectDate(TextEditingController ctrl,
      {DateTime? minDate, bool isFrom = false}) async {
    DateTime initialDate = DateTime.now();
    if (ctrl.text.isNotEmpty) {
      initialDate = DateFormat('dd-MM-yyyy').parse(ctrl.text);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate ?? DateTime(2022),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        ctrl.text = DateFormat('dd-MM-yyyy').format(picked);
        if (isFrom) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = null;
            toCtrl.clear();
          }
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _saveLeave() async {
    if (!_formKey.currentState!.validate()) return;

    if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('To Date cannot be before From Date'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Check admin access
    if (!_isAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only admin can create leave types'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final token = _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Not logged in'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isEditMode) {
      return _updateLeave(token);
    }

    final body = {
      'type': typeCtrl.text.trim(),
      'shift': shiftCtrl.text.trim(),
      // backend expects ISO-like dates; use yyyy-MM-dd
      'fromDate': DateFormat('yyyy-MM-dd').format(fromDate!),
      'toDate': DateFormat('yyyy-MM-dd').format(toDate!),
      'days': int.tryParse(daysCtrl.text.trim()) ?? 1,
    };

    try {
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/leave-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201) {
        final responseData = resp.body.isNotEmpty
            ? jsonDecode(resp.body) as Map<String, dynamic>
            : <String, dynamic>{};
        final savedData = responseData['data'] is Map<String, dynamic>
            ? responseData['data'] as Map<String, dynamic>
            : responseData;

        leaveList.add({
          'id': savedData['id']?.toString() ?? '',
          'type': typeCtrl.text.trim(),
          'shift': shiftCtrl.text.trim(),
          'fromDate': fromCtrl.text,
          'toDate': toCtrl.text,
          'allowedDays': daysCtrl.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave type saved')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  Future<void> _updateLeave(String token) async {
    if (_editingId == null || _editingId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update leave type. Missing ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final body = {
      'type': typeCtrl.text.trim(),
      'shift': shiftCtrl.text.trim(),
      'fromDate': DateFormat('yyyy-MM-dd').format(fromDate!),
      'toDate': DateFormat('yyyy-MM-dd').format(toDate!),
      'days': int.tryParse(daysCtrl.text.trim()) ?? 1,
    };

    try {
      final resp = await http.put(
        Uri.parse('${ApiService.baseUrl}/leave-types/${Uri.encodeComponent(_editingId!)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave type updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAuth) {
      return Scaffold(
        appBar: AppBar(
            title: Text(_isEditMode ? 'Edit Leave Type' : 'Add Leave Type'),
            backgroundColor: kAppBarColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final role = _getUserRole();

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Leave Type' : 'Add Leave Type'),
          backgroundColor: kAppBarColor),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildField('Type', typeCtrl),
                _buildField('Shift', shiftCtrl, isRequired: false),
                _buildDateField('From Date', fromCtrl, isFrom: true),
                _buildDateField('To Date', toCtrl, minDate: fromDate),
                _buildField('Number of Days', daysCtrl, inputType: TextInputType.number),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kButtonColor,
                        side: const BorderSide(color: kButtonColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdmin() ? kButtonColor : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isAdmin() ? _saveLeave : null,
                      child: Text(_isAdmin()
                          ? (_isEditMode ? 'Update Leave' : 'Create')
                          : 'Admin Only'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType? inputType, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(color: kAppBarColor),
        decoration: _getDecor(label),
        validator: isRequired
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController ctrl,
      {DateTime? minDate, bool isFrom = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        style: const TextStyle(color: kAppBarColor),
        decoration: _getDecor(label).copyWith(
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: kAppBarColor),
            onPressed: () =>
                _selectDate(ctrl, minDate: minDate, isFrom: isFrom),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Select date' : null,
      ),
    );
  }

  InputDecoration _getDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kAppBarColor),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kAppBarColor, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kAppBarColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }
}
