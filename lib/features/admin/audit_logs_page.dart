import 'package:flutter/material.dart';
import 'package:serv_app/services/audit_log_service.dart';
import 'package:serv_app/shared/app_theme.dart';

const double _kTableWidth = 1100;

const _kSensitiveKey = <String>[
  'password',
  'passwd',
  'hash',
  'otp',
  'token',
  'jwt',
  'authorization',
  'secret',
  'private',
  'key',
  'credential',
  'session',
];

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final TextEditingController _employeeSearch = TextEditingController();
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  String? _error;
  String _actionFilter = 'all';
  DateTimeRange? _dateRange;

  static const _actionOptions = <String, String>{
    'all': 'All',
    'EMPLOYEE_CREATED': 'Created Employee',
    'EMPLOYEE_UPDATED': 'Updated Employee',
    'EMPLOYEE_SOFT_DELETED': 'Removed Employee',
    'REQUEST_APPROVED': 'Approved Request',
    'REQUEST_REJECTED': 'Rejected Request',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _employeeSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await AuditLogService.getAuditLogs();
      logs.sort((a, b) {
        final ta = _parseTimestamp(a['timestamp']);
        final tb = _parseTimestamp(b['timestamp']);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load audit logs.';
        _loading = false;
      });
    }
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000,
        ).toLocal();
      }
      final nanos = value['_nanoseconds'] ?? value['nanoseconds'];
      if (seconds == null && nanos == null) return null;
    }
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    var hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year} $hour:$minute $ampm';
  }

  static String _actionLabel(String? action) {
    switch (action) {
      case 'EMPLOYEE_CREATED':
        return 'Created Employee';
      case 'EMPLOYEE_UPDATED':
        return 'Updated Employee';
      case 'EMPLOYEE_SOFT_DELETED':
        return 'Removed Employee';
      case 'REQUEST_APPROVED':
        return 'Approved Request';
      case 'REQUEST_REJECTED':
        return 'Rejected Request';
      case 'employee.joined':
        return 'Employee Joined';
      case 'employee.transferred':
        return 'Employee Transferred';
      case 'employee.designation_changed':
        return 'Designation Changed';
      case 'employee.department_changed':
        return 'Department Changed';
      case 'employee.status_changed':
        return 'Status Changed';
      case 'employee.relieved':
        return 'Employee Relieved';
      case 'employee.employment_type_changed':
        return 'Employment Type Changed';
      case 'employee.probation_changed':
        return 'Probation Changed';
      case 'payroll.marked_paid':
        return 'Payroll Marked Paid';
      default:
        return (action == null || action.isEmpty) ? 'Unknown' : action;
    }
  }

  static String _humanFieldLabel(String key) {
    const labels = {
      'isDeleted': 'Deleted',
      'empid': 'Employee ID',
      'employeeId': 'Employee ID',
      'employeeName': 'Employee Name',
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'status': 'Status',
      'dept': 'Department',
      'desig': 'Designation',
      'branch': 'Branch',
      'costCenter': 'Cost Center',
      'employmentType': 'Employment Type',
      'joiningDate': 'Joining Date',
      'probationStatus': 'Probation Status',
      'probationStartDate': 'Probation Start Date',
      'probationEndDate': 'Probation End Date',
      'shift': 'Shift',
      'shiftId': 'Shift',
      'branchId': 'Branch',
      'deptId': 'Department',
      'desigId': 'Designation',
      'costCenterId': 'Cost Center',
      'role': 'Role',
      'gender': 'Gender',
      'dob': 'Date of Birth',
      'bloodGroup': 'Blood Group',
      'maritalStatus': 'Marital Status',
      'nationality': 'Nationality',
      'address': 'Address',
      'city': 'City',
      'state': 'State',
      'zipCode': 'ZIP Code',
      'fatherName': "Father's Name",
      'motherName': "Mother's Name",
      'emergencyContactName': 'Emergency Contact',
      'emergencyContactPhone': 'Emergency Contact Phone',
    };
    if (labels.containsKey(key)) return labels[key]!;
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return _kSensitiveKey.any((s) => lower.contains(s));
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (_isSensitiveKey(key)) continue;
      result[key] = entry.value;
    }
    return result;
  }

  static String _valueText(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is Map) {
      final parsed = _parseTimestamp(v);
      if (parsed != null) return _formatDateTime(parsed);
      return v.values.map(_valueText).join(' ');
    }
    if (v is List) return v.map(_valueText).join(', ');
    return v.toString();
  }

  List<MapEntry<String, MapEntry<dynamic, dynamic>>> _changedFields(
    Map<String, dynamic> log,
  ) {
    final before = _safeMap(log['before']);
    final after = _safeMap(log['after']);
    final changes = <MapEntry<String, MapEntry<dynamic, dynamic>>>[];
    for (final key in after.keys) {
      final b = before.containsKey(key) ? before[key] : null;
      changes.add(MapEntry(key, MapEntry(b, after[key])));
    }
    for (final key in before.keys) {
      if (!after.containsKey(key)) {
        changes.add(MapEntry(key, MapEntry(before[key], null)));
      }
    }
    return changes;
  }

  static const Map<String, String> _requestTypeLabels = {
    'leave': 'Leave Type',
    'leave type': 'Leave Type',
    'late check-in': 'Late Check In',
    'late check in': 'Late Check In',
    'early check-out': 'Early Check Out',
    'early check out': 'Early Check Out',
  };

  static String? _requestTypeLabel(Map<String, dynamic> log) {
    final meta = log['metadata'];
    final raw = [
      log['requestType'],
      if (meta is Map) meta['requestType'],
    ]
        .map((v) => '${v ?? ''}'.trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return null;
    return _requestTypeLabels[raw.toLowerCase()] ?? raw;
  }

  String _changesPreview(Map<String, dynamic> log) {
    final action = log['action'] as String?;
    if (action == 'EMPLOYEE_CREATED') return 'Employee created';
    if (action == 'EMPLOYEE_SOFT_DELETED') return 'Employee removed';
    final changes = _changedFields(log);
    if (changes.isEmpty) return '—';
    final first = changes.first;
    final text =
        '${_humanFieldLabel(first.key)}: ${_valueText(first.value.key)} → ${_valueText(first.value.value)}';
    final prefix = _requestTypeLabel(log);
    final base =
        changes.length > 1 ? '$text (+${changes.length - 1} more)' : text;
    return prefix == null ? base : '$prefix · $base';
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final q = _employeeSearch.text.trim().toLowerCase();
    return _logs.where((log) {
      if (_actionFilter != 'all' && log['action'] != _actionFilter) {
        return false;
      }
      if (_dateRange != null) {
        final t = _parseTimestamp(log['timestamp']);
        if (t == null) return false;
        final start = _dateRange!.start;
        final end = _dateRange!.end.add(const Duration(days: 1));
        if (t.isBefore(start) || !t.isBefore(end)) return false;
      }
      if (q.isEmpty) return true;
      final name = '${log['employeeName'] ?? ''}'.toLowerCase();
      final id = '${log['employeeId'] ?? ''}'.toLowerCase();
      final actor = '${log['actorName'] ?? ''}'.toLowerCase();
      return name.contains(q) || id.contains(q) || actor.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track administrative actions and changes across employee records.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    final searchField = TextField(
      controller: _employeeSearch,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search employee / admin',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        fillColor: kFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final actionDropdown = DropdownButtonFormField<String>(
      initialValue: _actionFilter,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Action',
        filled: true,
        fillColor: kFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _actionOptions.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _actionFilter = v ?? 'all'),
    );
    final secondaryControls = <Widget>[
      OutlinedButton.icon(
        onPressed: _pickDateRange,
        icon: const Icon(Icons.date_range, size: 18),
        label: Text(
          _dateRange == null
              ? 'Date range'
              : '${_fmtShort(_dateRange!.start)} – ${_fmtShort(_dateRange!.end)}',
        ),
      ),
      if (_dateRange != null)
        TextButton(
          onPressed: () => setState(() => _dateRange = null),
          child: const Text('Clear'),
        ),
      IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
        color: kPrimaryDark,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 8),
                actionDropdown,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: secondaryControls,
                ),
              ],
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 240, child: searchField),
              SizedBox(width: 180, child: actionDropdown),
              ...secondaryControls,
            ],
          );
        },
      ),
    );
  }

  static String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: kPrimaryDark,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade500, size: 40),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('No audit logs found.'));
    }
    final filtered = _filteredLogs;
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No audit logs match the selected filters.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _kTableWidth,
        child: Column(
          children: [
            _buildHeaderRow(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildRow(filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    return Container(
      height: 44,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: const [
          SizedBox(width: 170, child: Text('Date & Time', style: style)),
          SizedBox(width: 200, child: Text('Performed By', style: style)),
          SizedBox(width: 150, child: Text('Action', style: style)),
          SizedBox(width: 180, child: Text('Employee', style: style)),
          Expanded(child: Text('Changes', style: style)),
          SizedBox(width: 80, child: Text('Details', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> log) {
    final timestamp = _parseTimestamp(log['timestamp']);
    final actorName = '${log['actorName'] ?? ''}'.trim();
    final actorEmail = '${log['actorEmail'] ?? ''}'.trim();
    final employeeName = '${log['employeeName'] ?? ''}'.trim();
    final employeeId = '${log['employeeId'] ?? ''}'.trim();
    final action = log['action'] as String?;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              _formatDateTime(timestamp),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actorName.isEmpty ? '—' : actorName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (actorEmail.isNotEmpty)
                  Text(
                    actorEmail,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: _actionChip(action),
          ),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  employeeName.isEmpty ? '—' : employeeName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (employeeId.isNotEmpty)
                  Text(
                    employeeId,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _changesPreview(log),
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: TextButton(
              onPressed: () => _showDetails(log),
              child: const Text('View', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String? action) {
    Color bg;
    Color fg;
    switch (action) {
      case 'EMPLOYEE_CREATED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'EMPLOYEE_UPDATED':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case 'EMPLOYEE_SOFT_DELETED':
      case 'REQUEST_REJECTED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      case 'REQUEST_APPROVED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      default:
        bg = kFieldBg;
        fg = kPrimaryDark;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _actionLabel(action),
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: kPrimaryDark, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _actionLabel(log['action'] as String?),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Date & Time',
                    _formatDateTime(_parseTimestamp(log['timestamp']))),
                _detailRow('Performed By', _display(log['actorName'])),
                _detailRow('Actor Email', _display(log['actorEmail'])),
                _detailRow('Employee', _display(log['employeeName'])),
                _detailRow('Employee ID', _display(log['employeeId'])),
                if ((log['action'] as String?)?.startsWith('REQUEST_') ?? false)
                  _detailRow('Request Type', _requestTypeLabel(log) ?? '—'),
                if ('${(log['metadata'] as Map?)?['remarks'] ?? ''}'
                    .trim()
                    .isNotEmpty)
                  _detailRow('Remarks',
                      _display((log['metadata'] as Map?)?['remarks'])),
                _detailRow('Module', _display(log['module'])),
                const SizedBox(height: 12),
                const Text(
                  'Changes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _changesDetail(log),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Technical details',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  children: [
                    _detailRow('Resource ID', _display(log['resourceId'])),
                    _detailRow('Actor ID', _display(log['actorId'])),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _display(dynamic v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? '—' : s;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _changesDetail(Map<String, dynamic> log) {
    final action = log['action'] as String?;
    final changes = _changedFields(log);

    if (action == 'EMPLOYEE_CREATED') {
      final name = _display(log['employeeName']);
      final id = _display(log['employeeId']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Created employee: $name ($id)',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          ...changes.map((c) => _changeRow(
              _humanFieldLabel(c.key), '—', _valueText(c.value.value))),
        ],
      );
    }

    if (changes.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes
          .map((c) => _changeRow(_humanFieldLabel(c.key),
              _valueText(c.value.key), _valueText(c.value.value)))
          .toList(),
    );
  }

  Widget _changeRow(String label, String before, String after) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(
                      text: before,
                      style: TextStyle(color: Colors.grey.shade600)),
                  const TextSpan(text: '  →  '),
                  TextSpan(
                    text: after,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: kPrimaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
