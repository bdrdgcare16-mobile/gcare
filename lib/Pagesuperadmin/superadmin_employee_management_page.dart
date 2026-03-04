import 'package:flutter/material.dart';

import 'employee_requests_page.dart'; // EmployeeRequestVm, EmployeeDetailsPage
import 'superadmin_dashboard.dart'; // EmployeeRequestVm, RequestStatus

class SuperAdminEmployeeManagementPage extends StatefulWidget {
  final List<EmployeeRequestVm> employees;
  final List<EmployeeRequestVm> approvedEmployees;

  const SuperAdminEmployeeManagementPage({
    super.key,
    required this.employees,
    required this.approvedEmployees,
  });

  @override
  State<SuperAdminEmployeeManagementPage> createState() => _SuperAdminEmployeeManagementPageState();
}

class _SuperAdminEmployeeManagementPageState extends State<SuperAdminEmployeeManagementPage> {
  static const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
  static const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
  static const Color kAppBarColor = Color(0xFF8C6EAF);
  static const Color kButtonColor = Color(0xFF655193);
  static const Color kTextColor = Colors.white;
  static const Color kBorder = Color(0xFFE3E7EE);

  static const String kDeptOther = '__DEPT_OTHER__';
  static const String kRoleOther = '__ROLE_OTHER__';

  static const String kAllDepartment = 'All Department';
  static const String kAllRoles = 'All Roles';
  static const String kSelectDate = 'Select Date';

  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  String _deptValue = kAllDepartment;
  String _roleValue = kAllRoles;
  DateTime? _selectedDate;

  late List<String> _allDeptOptions;
  late List<String> _allRoleOptions;

  @override
  void initState() {
    super.initState();
    _refreshOptions();
  }

  @override
  void didUpdateWidget(covariant SuperAdminEmployeeManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.approvedEmployees != widget.approvedEmployees) {
      _refreshOptions(keepCustom: true);
    }
  }

  void _refreshOptions({bool keepCustom = false}) {
    // Use fixed predefined departments and roles
    final predefinedDepts = ['HR', 'AE', 'Operations', 'AI', 'Admin'];
    final predefinedRoles = ['Manager', 'Team Lead', 'Executive', 'Staff', 'Intern'];

    if (!keepCustom) {
      _allDeptOptions = predefinedDepts;
      _allRoleOptions = predefinedRoles;
    } else {
      // Keep custom additions when updating
      _allDeptOptions = _mergeUniqueSorted(predefinedDepts, _allDeptOptions);
      _allRoleOptions = _mergeUniqueSorted(predefinedRoles, _allRoleOptions);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Top 5 + Other + keep selected visible
    final deptItems = _buildLimitedItems(
      header: kAllDepartment,
      values: _allDeptOptions,
      selectedValue: _deptValue,
      otherKey: kDeptOther,
    );

    final roleItems = _buildLimitedItems(
      header: kAllRoles,
      values: _allRoleOptions,
      selectedValue: _roleValue,
      otherKey: kRoleOther,
    );

    final filtered = _applyFilters(widget.approvedEmployees);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Management"),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Return to SuperAdminDashboard
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
          _filtersBar(context, deptItems: deptItems, roleItems: roleItems),
          const SizedBox(height: 6),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      "No matching employees found",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      final m = r.details;

                      final approved = _approvedDateOf(r);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFE9EEF7),
                              child: Text(
                                _initials(m.fullName),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Emp ID: ${m.employeeId}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  Text(
                                    "Department: ${_deptOf(r)}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  Text(
                                    "Role: ${_roleOf(r)}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  if (approved != null)
                                    Text(
                                      "Approved: ${_formatDate(approved)}",
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmployeeDetailsPage(request: r),
                                  ),
                                );
                              },
                              child: const Text("View"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  // ---------------- Filters UI ----------------

  Widget _filtersBar(
    BuildContext context, {
    required List<_DropItem> deptItems,
    required List<_DropItem> roleItems,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: "Search Employees...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.blue[800]!, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropBox(
                  value: _deptValue,
                  items: deptItems,
                  onChanged: (v) async {
                    if (v == null) return;

                    if (v == kDeptOther) {
                      final added = await _showAddDialog(
                        title: "Add Department",
                        hint: "Enter department name",
                      );
                      if (added != null) {
                        setState(() {
                          _allDeptOptions = _addUnique(_allDeptOptions, added);
                          _deptValue = added;
                        });
                      }
                      return;
                    }

                    setState(() => _deptValue = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropBox(
                  value: _roleValue,
                  items: roleItems,
                  onChanged: (v) async {
                    if (v == null) return;

                    if (v == kRoleOther) {
                      final added = await _showAddDialog(
                        title: "Add Role",
                        hint: "Enter role name",
                      );
                      if (added != null) {
                        setState(() {
                          _allRoleOptions = _addUnique(_allRoleOptions, added);
                          _roleValue = added;
                        });
                      }
                      return;
                    }

                    setState(() => _roleValue = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateBox(
                  label: _selectedDate == null ? kSelectDate : _formatDate(_selectedDate!),
                  onTap: () => _pickDate(context),
                  onClear: _selectedDate == null ? null : () => setState(() => _selectedDate = null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropBox({
    required String value,
    required List<_DropItem> items,
    required Future<void> Function(String? v) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          items: items
              .map(
                (it) => DropdownMenuItem<String>(
                  value: it.value,
                  child: Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _selectedDate ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<String?> _showAddDialog({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final v = ctrl.text.trim();
                Navigator.pop(ctx, v.isEmpty ? null : v);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonColor,
                foregroundColor: kTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
    return result;
  }

  // ---------------- Build dropdown list: All + 5 values + Other ----------------

  List<_DropItem> _buildLimitedItems({
    required String header,
    required List<String> values,
    required String selectedValue,
    required String otherKey,
  }) {
    // Use fixed predefined values (first 5)
    final predefinedDepts = ['HR', 'AE', 'Operations', 'AI', 'Admin'];
    final predefinedRoles = ['Manager', 'Team Lead', 'Executive', 'Staff', 'Intern'];
    
    // Determine which predefined list to use based on header
    final fixedValues = header == kAllDepartment ? predefinedDepts : predefinedRoles;

    final items = <_DropItem>[
      _DropItem(value: header, label: header),
      ...fixedValues.map((e) => _DropItem(value: e, label: e)),
      _DropItem(value: otherKey, label: 'Other...'),
    ];

    // If selected is not in fixed values, keep it visible in the list
    final alreadyIn = items.any((x) => x.value == selectedValue);
    if (!alreadyIn) {
      items.insert(1, _DropItem(value: selectedValue, label: selectedValue));
    }

    return items;
  }

  // ---------------- Filtering logic ----------------

  List<EmployeeRequestVm> _applyFilters(List<EmployeeRequestVm> source) {
    final q = _query.trim().toLowerCase();

    bool matchQuery(EmployeeRequestVm r) {
      if (q.isEmpty) return true;
      final name = r.details.fullName.toLowerCase();
      final id = r.details.employeeId.toLowerCase();
      return name.contains(q) || id.contains(q);
    }

    bool matchDept(EmployeeRequestVm r) {
      if (_deptValue == kAllDepartment) return true;
      return _deptOf(r).toLowerCase() == _deptValue.toLowerCase();
    }

    bool matchRole(EmployeeRequestVm r) {
      if (_roleValue == kAllRoles) return true;
      return _roleOf(r).toLowerCase() == _roleValue.toLowerCase();
    }

    bool matchDate(EmployeeRequestVm r) {
      if (_selectedDate == null) return true;
      final d = _approvedDateOf(r);
      if (d == null) return false;
      final only = DateTime(d.year, d.month, d.day);
      return only == _selectedDate;
    }

    return source.where((r) => matchQuery(r) && matchDept(r) && matchRole(r) && matchDate(r)).toList();
  }

  // ---------------- Options helpers ----------------

  
  List<String> _mergeUniqueSorted(List<String> a, List<String> b) {
    final merged = {...a, ...b}.toList();
    merged.sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    return merged;
  }

  List<String> _addUnique(List<String> list, String value) {
    final v = value.trim();
    if (v.isEmpty) return list;
    final exists = list.any((e) => e.toLowerCase() == v.toLowerCase());
    if (exists) return list;
    final next = [...list, v];
    next.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return next;
  }

  // ---------------- Model mapping (THIS is the key for your issue) ----------------
  // If this returns empty, dropdown will show only All + Other.

  String _deptOf(EmployeeRequestVm r) {
    final d = (r.details.department).trim();
    // Fallback to avoid empty list if your data is missing department
    return d.isEmpty ? 'General' : d;
  }

  String _roleOf(EmployeeRequestVm r) {
    final dynamic details = r.details;

    try {
      final role = (details.role as String?)?.trim();
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}

    try {
      final desig = (details.designation as String?)?.trim();
      if (desig != null && desig.isNotEmpty) return desig;
    } catch (_) {}

    return 'Staff'; // fallback
  }

  /// Update this to your real approval date field if required.
  DateTime? _approvedDateOf(EmployeeRequestVm r) {
    return r.decidedAt; // <-- if null for all, date filter won't match anything
  }

  // ---------------- Misc helpers ----------------

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd-$mm-$yyyy";
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";
    return parts.map((e) => e.isNotEmpty ? e[0] : "").take(2).join().toUpperCase();
  }
}

class _DropItem {
  final String value;
  final String label;
  const _DropItem({required this.value, required this.label});
}
