import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/employee_job_history_service.dart';

class EmployeeJobHistoryPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String employeeCode;

  const EmployeeJobHistoryPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
  });

  @override
  State<EmployeeJobHistoryPage> createState() => _EmployeeJobHistoryPageState();
}

class _EmployeeJobHistoryPageState extends State<EmployeeJobHistoryPage> {
  static const _historyFields = <_HistoryField>[
    _HistoryField('Branch', ['location'], ['branchId'], 'branch'),
    _HistoryField('Department', ['dept'], ['departmentId'], 'department'),
    _HistoryField(
        'Designation', ['designation'], ['designationId'], 'designation'),
    _HistoryField('Cost Center', [], ['costCenterId'], 'cost_center'),
    _HistoryField('Reporting Manager', [], ['reportingManagerId'], 'employee'),
    _HistoryField('Employment Type', ['employmentType'], [], null),
    _HistoryField('Joining Date', ['joiningDate'], [], null, isDate: true),
    _HistoryField('Probation Start Date', ['probationStartDate'], [], null,
        isDate: true),
    _HistoryField('Probation End Date', ['probationEndDate'], [], null,
        isDate: true),
    _HistoryField('Probation Status', ['probationStatus'], [], null),
  ];

  List<Map<String, dynamic>> _history = [];
  Map<String, String> _branchNames = {};
  Map<String, String> _departmentNames = {};
  Map<String, String> _designationNames = {};
  Map<String, String> _costCenterNames = {};
  Map<String, String> _employeeNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _loadNameMap(
    String path,
    String idKey,
    String Function(Map<String, dynamic>) label, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response =
          await ApiService.get(path, queryParameters: queryParameters);
      if (response.statusCode != 200 || response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      final items = decoded is List
          ? decoded
          : decoded is Map && decoded['data'] is List
              ? decoded['data'] as List
              : <dynamic>[];
      final result = <String, String>{};
      for (final raw in items.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        final id = (item[idKey] ?? '').toString();
        final name = label(item).trim();
        if (id.isNotEmpty && name.isNotEmpty) result[id] = name;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await EmployeeJobHistoryService.list(widget.employeeId);
      final lookups = await Future.wait<Map<String, String>>([
        _loadNameMap(
          '/office/locations',
          'docId',
          (item) => (item['branchName'] ?? item['name'] ?? '').toString(),
        ),
        _loadNameMap(
          '/organization/units',
          'id',
          (item) => (item['name'] ?? '').toString(),
          queryParameters: const {'type': 'department'},
        ),
        _loadNameMap(
          '/organization/units',
          'id',
          (item) => (item['name'] ?? '').toString(),
          queryParameters: const {'type': 'designation'},
        ),
        _loadNameMap(
          '/organization/units',
          'id',
          (item) {
            final name = (item['name'] ?? '').toString();
            final code = (item['code'] ?? '').toString();
            return code.isEmpty ? name : '$name ($code)';
          },
          queryParameters: const {'type': 'cost_center'},
        ),
        _loadNameMap(
          '/employees',
          'id',
          (item) => '${item['name'] ?? ''} (${item['empid'] ?? ''})',
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _history = history;
        _branchNames = lookups[0];
        _departmentNames = lookups[1];
        _designationNames = lookups[2];
        _costCenterNames = lookups[3];
        _employeeNames = lookups[4];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    return date == null
        ? raw
        : DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  String? _resolveFieldValue(
    Map<String, dynamic> source,
    _HistoryField field,
  ) {
    for (final key in field.readableKeys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return field.isDate ? _formatDate(value) : value.toString().trim();
      }
    }

    for (final key in field.idKeys) {
      final id = source[key]?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final names = switch (field.lookupType) {
        'branch' => _branchNames,
        'department' => _departmentNames,
        'designation' => _designationNames,
        'cost_center' => _costCenterNames,
        'employee' => _employeeNames,
        _ => const <String, String>{},
      };
      return names[id] ?? 'Assigned';
    }
    return null;
  }

  List<_HistoryField> _fieldsFor(String eventType) {
    switch (eventType) {
      case 'JOINED':
        return _historyFields;
      case 'TRANSFERRED':
        return [_historyFields[0]];
      case 'DEPARTMENT_CHANGED':
        return [_historyFields[1]];
      case 'DESIGNATION_CHANGED':
      case 'PROMOTED':
        return [_historyFields[2]];
      case 'COST_CENTER_CHANGED':
        return [_historyFields[3]];
      case 'MANAGER_CHANGED':
        return [_historyFields[4]];
      case 'EMPLOYMENT_CHANGED':
        return _historyFields.skip(5).toList();
      default:
        return _historyFields;
    }
  }

  String _eventTitle(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _snapshot(Map<String, dynamic> data, List<_HistoryField> fields) {
    final rows = <Widget>[];
    for (final field in fields) {
      final value = _resolveFieldValue(data, field);
      if (value == null || value.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, softWrap: true),
          ],
        ),
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _changeValues(Map<String, dynamic> before, Map<String, dynamic> after,
      _HistoryField field) {
    final oldValue = _resolveFieldValue(before, field);
    final newValue = _resolveFieldValue(after, field);
    if ((oldValue == null || oldValue.isEmpty) &&
        (newValue == null || newValue.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          _valueBlock('Previous', oldValue ?? 'Unassigned'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward, size: 18),
          ),
          _valueBlock('New', newValue ?? 'Unassigned'),
        ],
      ),
    );
  }

  Widget _valueBlock(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, softWrap: true),
        ],
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> entry) {
    final eventType = (entry['eventType'] ?? '').toString().toUpperCase();
    final before = entry['before'] is Map
        ? Map<String, dynamic>.from(entry['before'] as Map)
        : <String, dynamic>{};
    final after = entry['after'] is Map
        ? Map<String, dynamic>.from(entry['after'] as Map)
        : <String, dynamic>{};
    final effectiveDate = _formatDate(entry['effectiveDate']);
    final fields = _fieldsFor(eventType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(_eventTitle(eventType)),
                  backgroundColor: const Color(0xFFEDE7F6),
                  labelStyle: const TextStyle(color: Color(0xFF4A3475)),
                ),
                if (effectiveDate.isNotEmpty)
                  Text('Effective Date: $effectiveDate'),
              ],
            ),
            if (eventType == 'JOINED')
              _snapshot(after, fields)
            else
              for (final field in fields) _changeValues(before, after, field),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Job History'),
        backgroundColor: const Color(0xFF8C6EAF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('Employee: ${widget.employeeName}', softWrap: true),
                      Text('Employee ID: ${widget.employeeCode}',
                          softWrap: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                )
              else if (_history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No job history recorded yet.')),
                  ),
                )
              else
                for (final entry in _history) _eventCard(entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryField {
  final String label;
  final List<String> readableKeys;
  final List<String> idKeys;
  final String? lookupType;
  final bool isDate;

  const _HistoryField(
    this.label,
    this.readableKeys,
    this.idKeys,
    this.lookupType, {
    this.isDate = false,
  });
}
