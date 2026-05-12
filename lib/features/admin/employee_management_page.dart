import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF655193);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

void _log(Object msg) {
  if (kDebugMode) {
    print(msg);
  }
}

class Employee {
  final String companyId;
  final String name;
  final String id;
  final String email;
  final String mobile;
  final String location;
  final String dept;
  final String designation;
  final String status;
  final String shiftGroup;
  final String? docId;
  final String? password;
  final String role;

  Employee({
    required this.companyId,
    required this.name,
    required this.id,
    required this.email,
    required this.mobile,
    required this.location,
    required this.dept,
    required this.designation,
    required this.status,
    required this.shiftGroup,
    this.docId,
    this.password,
    this.role = 'employee',
  });

  factory Employee.fromServer(Map<String, dynamic> j) {
    return Employee(
      companyId: (j['companyId'] ?? '').toString(),
      docId: j['id']?.toString(),
      id: (j['empid'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      mobile: (j['phone'] ?? '').toString(),
      location: (j['location'] ?? '').toString(),
      dept: (j['dept'] ?? '').toString(),
      designation: (j['designation'] ?? '').toString(),
      shiftGroup: (j['shiftGroup'] ?? '').toString(),
      status: ((j['status'] ?? 'active').toString().toLowerCase() == 'active')
          ? 'Active'
          : 'Inactive',
      role: (j['role'] ?? 'employee').toString(),
    );
  }

  Map<String, dynamic> toCreateBody() {
    return {
      'companyId': companyId,
      'name': name,
      'empid': id,
      'email': email,
      'phone': mobile,
      'password': password,
      'location': location,
      'dept': dept,
      'designation': designation,
      'shiftGroup': shiftGroup.isEmpty ? null : shiftGroup,
      'role': role,
    };
  }
}

class EmployeeService {
  static bool _looksLikeJwt(String v) {
    return RegExp(
      r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
    ).hasMatch(v);
  }

  static String? _readToken() {
    final mem = CompanyData.token;
    if (mem != null && mem.isNotEmpty) return mem;

    const candidates = [
      'token',
      'jwt',
      'authToken',
      'access_token',
      'accessToken',
      'id_token',
    ];

    for (final k in candidates) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }

    try {
      for (final k in candidates) {
        final v = html.window.sessionStorage[k];
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}

    try {
      for (final k in html.window.localStorage.keys) {
        final v = html.window.localStorage[k];
        if (v != null && _looksLikeJwt(v)) return v;
      }
    } catch (_) {}

    try {
      for (final k in html.window.sessionStorage.keys) {
        final v = html.window.sessionStorage[k];
        if (v != null && _looksLikeJwt(v)) return v;
      }
    } catch (_) {}

    return null;
  }

  static Map<String, String> _headers() {
    final token = _readToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-auth-token'] = token;
    }

    return headers;
  }

  static Future<Map<String, dynamic>> fetchEmployees({
    int limit = 20,
    String? lastDocId,
  }) async {
    String url = '${ApiService.baseUrl}/employees?limit=$limit';

    if (lastDocId != null && lastDocId.isNotEmpty) {
      url += '&lastDocId=$lastDocId';
    }

    final res = await http.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      final List<dynamic> raw = decoded is List
          ? decoded
          : decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : <dynamic>[];

      final employees = raw.map((e) {
        return Employee.fromServer(
          e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
        );
      }).toList();

      return {
        'employees': employees,
        'lastDocId': decoded is Map<String, dynamic> ? decoded['lastDocId'] : null,
      };
    }

    throw Exception('Failed to fetch employees (${res.statusCode})');
  }

  static Future<String> createEmployee(Employee e) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/employees'),
      headers: _headers(),
      body: jsonEncode(e.toCreateBody()),
    );

    if (res.statusCode == 201) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['id'] != null) return j['id'].toString();

      if (j['data'] is Map && (j['data'] as Map)['id'] != null) {
        return (j['data'] as Map)['id'].toString();
      }

      return '';
    }

    if (res.statusCode == 400) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['error']?.toString() ?? 'Validation failed';
    }

    throw Exception('Create failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> updateEmployee(
    String docId,
    Map<String, dynamic> updates,
  ) async {
    final res = await http.put(
      Uri.parse('${ApiService.baseUrl}/employees/$docId'),
      headers: _headers(),
      body: jsonEncode(updates),
    );

    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode}): ${res.body}');
    }
  }

  static Future<void> deleteEmployeeById(String docId) async {
    final res = await http.delete(
      Uri.parse('${ApiService.baseUrl}/employees/$docId'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Delete failed (${res.statusCode}): ${res.body}');
    }
  }

  static Future<List<String>> fetchShiftGroups() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/shifts'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load shifts (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    final list = decoded is List
        ? decoded
        : decoded is Map<String, dynamic> && decoded['data'] is List
            ? decoded['data'] as List
            : <dynamic>[];

    final names = <String>[];

    for (final it in list) {
      final m = it as Map<String, dynamic>;
      final n = (m['name'] ?? m['shiftname'] ?? '').toString().trim();
      if (n.isNotEmpty) names.add(n);
    }

    return names;
  }
}

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> employees = [];
  List<Employee> filtered = [];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;
  bool _loading = false;
  bool _isFetching = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (_hasMore) {
          _loadEmployees(loadMore: true);
        }
      }
    });
  }

  Future<void> _loadEmployees({bool loadMore = false}) async {
    if (_isFetching) return;

    _isFetching = true;

    if (!loadMore) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await EmployeeService.fetchEmployees();
      final List<Employee> newEmployees = result['employees'];

      if (!mounted) return;

      setState(() {
        employees = newEmployees;
        filtered = newEmployees;
        _hasMore = false;
        _loading = false;
      });
    } catch (e) {
      _log(e);

      if (!mounted) return;

      setState(() {
        _error = 'Failed to load employees';
        _loading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  void updateFiltered(String value) {
    final q = value.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        filtered = employees;
      } else {
        filtered = employees.where((e) {
          return e.id.toLowerCase().contains(q) ||
              e.name.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q) ||
              e.mobile.toLowerCase().contains(q) ||
              e.shiftGroup.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q) ||
              e.dept.toLowerCase().contains(q) ||
              e.designation.toLowerCase().contains(q) ||
              e.status.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  int countStatus(String status) {
    return employees
        .where((e) => e.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  Widget statButton(String label, int count) {
    return SizedBox(
      width: 88,
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          foregroundColor: kTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: () {},
        child: Text(
          '$label $count',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _cell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openCreateEmployee() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEmployeeScreen(),
      ),
    );

    if (result != true) return;

    // Employee was created successfully in CreateEmployeeScreen
    // Just reload the employee list and show success message
    await _loadEmployees();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee created')),
    );
  }

  Future<void> _deleteEmployee(Employee e) async {
    final idToDelete = e.docId;

    if (idToDelete == null || idToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing server id for this employee')),
      );
      return;
    }

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete employee?'),
          content: Text('This will permanently delete ${e.name}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (sure != true) return;

    try {
      await EmployeeService.deleteEmployeeById(idToDelete);
      await _loadEmployees();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted')),
      );
    } catch (err) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $err')),
      );
    }
  }

  Future<void> _editEmployee(Employee e) async {
    final edited = await Navigator.push<Employee>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEmployeeScreen(editEmployee: e),
      ),
    );

    if (edited == null) return;

    if (e.docId == null || e.docId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing server id for this employee')),
      );
      return;
    }

    try {
      await EmployeeService.updateEmployee(e.docId!, {
        'name': edited.name,
        'empid': edited.id,
        'email': edited.email,
        'phone': edited.mobile,
        'location': edited.location,
        'dept': edited.dept,
        'designation': edited.designation,
        'shiftGroup': edited.shiftGroup,
        'status': edited.status.toLowerCase(),
      });

      await _loadEmployees();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated')),
      );
    } catch (err) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $err')),
      );
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF5F3FF),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 6,
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 8,
            child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 7,
            child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              'Shift Group',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              'Department',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              'Designation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(Employee e) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell(e.id, flex: 4),
          _cell(e.name, flex: 6),
          _cell(e.email, flex: 8),
          _cell(e.mobile, flex: 7),
          _cell(e.shiftGroup, flex: 6),
          _cell(e.location, flex: 6),
          _cell(e.dept, flex: 6),
          _cell(e.designation, flex: 6),
          _cell(e.status, flex: 4),
          Expanded(
            flex: 5,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteEmployee(e),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editEmployee(e),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: kButtonColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No employees found'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1300,
            child: Column(
              children: [
                _buildTableHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildEmployeeRow(filtered[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  children: [
                    TextSpan(
                      text: 'Employee',
                      style: TextStyle(color: Color(0xFF1E1B4B)),
                    ),
                    TextSpan(
                      text: ' Management',
                      style: TextStyle(color: Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
  child: Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      statButton('Total', 22),
      statButton('Active', 21),
      statButton('Inactive', 1),
      statButton('Suspended', 0),
      statButton('Relived', 0),
    ],
  ),
),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: _openCreateEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      foregroundColor: kTextColor,
                      minimumSize: const Size(120, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Employee',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 300),
                      () => updateFiltered(value),
                    );
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: kButtonColor),
                    hintText: 'Search',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kButtonColor.withOpacity(0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildEmployeeTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateEmployeeScreen extends StatefulWidget {
  final Employee? editEmployee;

  const CreateEmployeeScreen({
    super.key,
    this.editEmployee,
  });

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final companyId = TextEditingController();
  final name = TextEditingController();
  final id = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final shiftgroup = TextEditingController();
  final password = TextEditingController();
  final location = TextEditingController();
  final dept = TextEditingController();
  final desig = TextEditingController();

  bool _obscurePassword = true;
  String status = 'Active';
  String dialCode = '+91';

  List<String> _shiftOptions = [];
  bool _shiftsLoading = false;
  String? _shiftsError;
  String? _emailError;
  String? _empidError;

  @override
  void initState() {
    super.initState();

    final emp = widget.editEmployee;

    if (emp != null) {
      companyId.text = emp.companyId;
      name.text = emp.name;
      id.text = emp.id;
      email.text = emp.email;
      mobile.text = emp.mobile.replaceFirst(RegExp(r'^\+\d+\s*'), '');
      shiftgroup.text = emp.shiftGroup;
      location.text = emp.location;
      dept.text = emp.dept;
      desig.text = emp.designation;
      status = emp.status;
    }

    _loadShiftGroups();
  }

  Future<void> _loadShiftGroups() async {
    setState(() {
      _shiftsLoading = true;
      _shiftsError = null;
    });

    try {
      final list = await EmployeeService.fetchShiftGroups();

      if (!mounted) return;

      setState(() {
        _shiftOptions = list;

        if (shiftgroup.text.isNotEmpty &&
            !_shiftOptions.contains(shiftgroup.text)) {
          _shiftOptions = [shiftgroup.text, ..._shiftOptions];
        }

        _shiftsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _shiftsError = 'Failed to load shifts';
        _shiftsLoading = false;
      });
    }
  }

  Widget formField(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';

          if (label == 'Email') {
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );

            if (!emailRegex.hasMatch(v.trim())) {
              return 'Enter valid email';
            }

            // Show email error if exists
            if (_emailError != null) {
              return _emailError;
            }
          }

          // Show employee ID error if exists
          if (label == 'Employee ID' && _empidError != null) {
            return _empidError;
          }

          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget passwordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: password,
        obscureText: _obscurePassword,
        validator: (v) {
          if (widget.editEmployee != null && (v == null || v.isEmpty)) {
            return null;
          }

          if (v == null || v.trim().isEmpty) return 'Required';

          if (v.trim().length < 6) return 'Password too short';

          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: const TextSpan(
              text: 'Password',
              style: TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget shiftDropdownField() {
    if (_shiftsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue:
            shiftgroup.text.isNotEmpty && _shiftOptions.contains(shiftgroup.text)
                ? shiftgroup.text
                : null,
        items: _shiftOptions.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            shiftgroup.text = value ?? '';
          });
        },
        validator: (value) {
          return value == null || value.isEmpty ? 'Required' : null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: const TextSpan(
              text: 'Shift Group',
              style: TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          helperText: _shiftsError,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Clear previous email error
    setState(() => _emailError = null);

    final newEmp = Employee(
      companyId: companyId.text.trim(),
      name: name.text.trim(),
      id: id.text.trim(),
      email: email.text.trim().toLowerCase(),
      mobile: '$dialCode ${mobile.text.trim()}',
      shiftGroup: shiftgroup.text.trim(),
      location: location.text.trim(),
      dept: dept.text.trim(),
      designation: desig.text.trim(),
      status: status,
      password: password.text.trim(),
      role: 'employee',
    );

    try {
      final response = await EmployeeService.createEmployee(newEmp);
      
      // Handle backend duplicate email response
      if (response.contains('Email already exists for this company')) {
        setState(() => _emailError = 'Email already exists for this company');
        _formKey.currentState?.validate(); // Revalidate to show error
        return;
      }
      
      // Handle backend duplicate employee ID response
      if (response.contains('Employee ID already exists for this company')) {
        setState(() => _empidError = 'Employee ID already exists for this company');
        _formKey.currentState?.validate(); // Revalidate to show error
        return;
      }
      
      // Handle other validation errors from backend
      if (response.contains('already exists')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response)),
        );
        return;
      }
      
      // Success - navigate back with success flag
      if (!mounted) return;
      Navigator.pop(context, true);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    companyId.dispose();
    name.dispose();
    id.dispose();
    email.dispose();
    mobile.dispose();
    shiftgroup.dispose();
    password.dispose();
    location.dispose();
    dept.dispose();
    desig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editEmployee != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Employee' : 'Create Employee',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: kAppBarColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                formField('Company ID', companyId),
                formField('Employee Name', name),
                formField('Employee ID', id),
                formField('Email', email, type: TextInputType.emailAddress),
                IntlPhoneField(
                  initialCountryCode: 'IN',
                  initialValue: mobile.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    label: const Text.rich(
                      TextSpan(
                        text: 'Mobile',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                        children: [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onChanged: (phone) {
                    dialCode = phone.countryCode;
                    mobile.text = phone.number;
                  },
                ),
                shiftDropdownField(),
                passwordField(),
                formField('Location', location),
                formField('Department', dept),
                formField('Designation', desig),
                Row(
                  children: [
                    const Text('Status: '),
                    Radio<String>(
                      value: 'Active',
                      groupValue: status,
                      onChanged: (val) {
                        setState(() {
                          status = val!;
                        });
                      },
                    ),
                    const Text('Active'),
                    Radio<String>(
                      value: 'Inactive',
                      groupValue: status,
                      onChanged: (val) {
                        setState(() {
                          status = val!;
                        });
                      },
                    ),
                    const Text('Inactive'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(isEdit ? 'Update' : 'Create'),
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
}