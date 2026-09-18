// lib/features/admin/task_assignment_history.dart
//
// Shared, table/sheet-style presentation of task assignment history for Admin.
//
// The backend (`GET /tasks/employee`) already returns one `taskAssignments`
// document per employee nested under each task. This file flattens that
// task -> assignments -> employee relationship into one row per employee so the
// Admin never loses the employee identity, and renders it in a horizontally
// scrollable table.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

const Color kTaskPrimary = Color(0xFF8C6EAF);
const Color kTaskPrimaryDark = Color(0xFF655193);
const Color kTaskHeaderBg = Color(0xFFEDE7F6);

const List<String> _kMonths = [
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

/// Converts a backend ISO / yyyy-MM-dd value into IST and formats it as
/// `01 Sep 2026`. Returns '-' when the backend has no value (never faked).
String formatTaskDate(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '-';

  // Plain yyyy-MM-dd (dueDate) has no timezone, so do not shift it.
  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (dateOnly != null) {
    final m = int.tryParse(dateOnly.group(2)!) ?? 1;
    return '${dateOnly.group(3)} ${_kMonths[(m - 1).clamp(0, 11)]} ${dateOnly.group(1)}';
  }

  final parsed = DateTime.tryParse(v);
  if (parsed == null) return v;
  final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${ist.day.toString().padLeft(2, '0')} '
      '${_kMonths[ist.month - 1]} ${ist.year}';
}

/// `02:35 PM` in IST, used for the optional "Completed Time" column.
String formatTaskTime(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '-';
  final parsed = DateTime.tryParse(v);
  if (parsed == null) return '-';
  final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
  final hour12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
  final ampm = ist.hour >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:'
      '${ist.minute.toString().padLeft(2, '0')} $ampm';
}

/// Returns the calendar day (IST) for date-range filtering, or null.
DateTime? taskDateOnly(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return null;

  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (dateOnly != null) {
    return DateTime(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    );
  }

  final parsed = DateTime.tryParse(v);
  if (parsed == null) return null;
  final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(ist.year, ist.month, ist.day);
}

/// Maps the backend status values (`assigned` / `in_progress` / `completed`)
/// to friendly labels. Backend values are never rewritten.
String taskStatusLabel(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'completed':
      return 'Completed';
    case 'in_progress':
    case 'inprogress':
      return 'In Progress';
    case 'pending':
      return 'Pending';
    case 'assigned':
      return 'Assigned';
    default:
      return raw.isEmpty ? 'Assigned' : raw;
  }
}

Color taskStatusColor(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'completed':
      return const Color(0xFF2E7D32);
    case 'in_progress':
    case 'inprogress':
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFFEF6C00);
  }
}

/// One row = one employee's assignment of one task.
class TaskAssignmentRow {
  final String taskId;
  final String assignmentId;
  final String employeeId;
  final String employeeName;
  final String title;
  final String description;
  final String assignedAt;
  final String dueDate;
  final String status;
  final String completedAt;
  final String completionNote;
  final String proofFileUrl;
  final String assignedBy;

  TaskAssignmentRow({
    required this.taskId,
    required this.assignmentId,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.description,
    required this.assignedAt,
    required this.dueDate,
    required this.status,
    required this.completedAt,
    required this.completionNote,
    required this.proofFileUrl,
    required this.assignedBy,
  });

  bool get isCompleted => status.trim().toLowerCase() == 'completed';

  bool get hasProof => proofFileUrl.trim().isNotEmpty;

  /// Flattens the `GET /tasks/employee` payload into one row per employee.
  ///
  /// - Tasks with assignment documents produce one row per assignment, so an
  ///   "All employees" broadcast is shown per employee, never as a single
  ///   "All Employees" line.
  /// - Legacy tasks that have no assignment document yet fall back to a single
  ///   row using the task's own `assignedTo` / `createdAt`.
  static List<TaskAssignmentRow> flatten(List<dynamic> tasks) {
    final rows = <TaskAssignmentRow>[];

    for (final raw in tasks) {
      if (raw is! Map) continue;
      final task = Map<String, dynamic>.from(raw);

      final kind =
          (task['kind'] ?? '').toString().toLowerCase().replaceAll(' ', '');
      // Daily updates are employee self-posts, not admin assignments.
      if (kind == 'dailyupdate') continue;

      final taskId = (task['id'] ?? '').toString();
      final title = (task['title'] ?? 'Task').toString();
      final description = (task['description'] ?? '').toString();
      final dueDate = (task['dueDate'] ?? '').toString();
      final createdAt = (task['createdAt'] ?? '').toString();
      final assignedBy = (task['createdByName'] ?? '').toString();

      final assignments = task['assignments'] is List
          ? List<dynamic>.from(task['assignments'] as List)
          : const <dynamic>[];

      if (assignments.isNotEmpty) {
        for (final a in assignments) {
          if (a is! Map) continue;
          final asg = Map<String, dynamic>.from(a);
          rows.add(
            TaskAssignmentRow(
              taskId: taskId,
              assignmentId: (asg['id'] ?? '').toString(),
              employeeId: (asg['employeeId'] ?? '').toString(),
              employeeName: (asg['employeeName'] ?? '').toString(),
              title: title,
              description: description,
              // Real assignment timestamp from the assignment document.
              assignedAt: (asg['assignedAt'] ?? createdAt).toString(),
              dueDate: dueDate,
              status: (asg['status'] ?? 'assigned').toString(),
              completedAt: (asg['completedAt'] ?? '').toString(),
              completionNote: (asg['completionNote'] ?? '').toString(),
              proofFileUrl: (asg['proofFileUrl'] ?? '').toString(),
              assignedBy: assignedBy,
            ),
          );
        }
        continue;
      }

      // Legacy task without assignment documents.
      final audience = (task['audience'] ?? 'all').toString();
      rows.add(
        TaskAssignmentRow(
          taskId: taskId,
          assignmentId: '',
          employeeId: audience == 'employee'
              ? (task['assignedTo'] ?? '').toString()
              : 'All employees',
          employeeName: (task['assignedToName'] ?? '').toString(),
          title: title,
          description: description,
          assignedAt: createdAt,
          dueDate: dueDate,
          status: (task['status'] ?? 'assigned').toString(),
          completedAt: (task['completedAt'] ?? '').toString(),
          completionNote: (task['completionNote'] ?? '').toString(),
          proofFileUrl: (task['proofFileUrl'] ?? '').toString(),
          assignedBy: assignedBy,
        ),
      );
    }

    // Default sort: newest assigned first, using the real assignment timestamp.
    rows.sort((a, b) {
      final ad = DateTime.tryParse(a.assignedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(b.assignedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return rows;
  }
}

/// Fetches admin task history and flattens it to employee-level rows.
Future<List<TaskAssignmentRow>> fetchTaskAssignmentRows() async {
  final uri = Uri.parse(
    '${ApiService.baseUrl}/tasks/employee'
    '?limit=200&t=${DateTime.now().millisecondsSinceEpoch}',
  );

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  final token = CompanyData.token;
  if (token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  final resp = await http.get(uri, headers: headers);
  if (resp.statusCode != 200) {
    throw Exception('Failed to load task history (${resp.statusCode})');
  }

  return TaskAssignmentRow.flatten(jsonDecode(resp.body) as List<dynamic>);
}

/// Opens the employee's uploaded proof using the existing signed-URL endpoint.
Future<void> openTaskProof(
  BuildContext context,
  String taskId,
  String employeeId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/tasks/$taskId/proof-url'
      '?empid=${Uri.encodeComponent(employeeId)}',
    );
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = CompanyData.token;
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final signedUrl = (data['url'] ?? '').toString();
      if (signedUrl.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to get proof URL')),
        );
        return;
      }
      final launched = await launchUrl(
        Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load proof: ${resp.statusCode}')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error loading proof: $e')));
  }
}

/// Returns a (from, to) calendar-date pair for the quick-filter chip labels.
({DateTime? from, DateTime? to})? quickDateRange(String range) {
  final now = DateTime.now();
  switch (range) {
    case 'Today':
      final d = DateTime(now.year, now.month, now.day);
      return (from: d, to: d);
    case 'Yesterday':
      final y = now.subtract(const Duration(days: 1));
      final d = DateTime(y.year, y.month, y.day);
      return (from: d, to: d);
    case 'Last 7 Days':
      final w = now.subtract(const Duration(days: 6));
      return (
        from: DateTime(w.year, w.month, w.day),
        to: DateTime(now.year, now.month, now.day)
      );
    case 'This Month':
      return (
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0)
      );
    case 'All':
      return (from: null, to: null);
  }
  return null;
}

/// Search + status + date-range filter bar shared by both admin tables.
class TaskHistoryFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final List<String> statusOptions;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String searchHint;
  final String dateLabel;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onClear;
  final ValueChanged<String>? onQuickFilter;

  const TaskHistoryFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.statusOptions,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onClear,
    this.onQuickFilter,
    this.searchHint = 'Search Employee ID / Name / Task Title',
    this.dateLabel = 'Assigned',
  });

  Widget _dateChip({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    double? width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 15, color: kTaskPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : '${value.day.toString().padLeft(2, '0')} '
                        '${_kMonths[value.month - 1]} ${value.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: value == null
                      ? const Color(0xFF888888)
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusFilter,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down,
              color: kTaskPrimary, size: 20),
          style: const TextStyle(
              fontSize: 12.5, color: Color(0xFF333333)),
          items: statusOptions
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s == 'All' ? 'All Status' : s,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onStatusChanged(v);
          },
        ),
      ),
    );
  }

  Widget _clearButton() {
    return SizedBox(
      height: 44,
      child: TextButton.icon(
        onPressed: onClear,
        icon: const Icon(Icons.clear_all, size: 18),
        label: const Text('Clear', style: TextStyle(fontSize: 12.5)),
        style: TextButton.styleFrom(
          foregroundColor: kTaskPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _quickFilterChips() {
    const ranges = ['All', 'Today', 'Yesterday', 'Last 7 Days', 'This Month'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ranges.map((r) {
        return ActionChip(
          label: Text(r, style: const TextStyle(fontSize: 11.5)),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          onPressed: () => onQuickFilter?.call(r),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = searchController.text.trim().isNotEmpty ||
        statusFilter != 'All' ||
        fromDate != null ||
        toDate != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;

        final fromChip = _dateChip(
          label: '$dateLabel From',
          value: fromDate,
          onTap: onPickFromDate,
          width: narrow ? double.infinity : null,
        );
        final toChip = _dateChip(
          label: '$dateLabel To',
          value: toDate,
          onTap: onPickToDate,
          width: narrow ? double.infinity : null,
        );
        final status = _statusDropdown();
        final clear = _clearButton();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: searchHint,
                hintStyle: const TextStyle(fontSize: 12.5),
                prefixIcon: const Icon(Icons.search, size: 19, color: kTaskPrimary),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            narrow
                ? Column(
                    children: [
                      fromChip,
                      const SizedBox(height: 8),
                      toChip,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: fromChip),
                      const SizedBox(width: 8),
                      Expanded(child: toChip),
                    ],
                  ),
            const SizedBox(height: 10),
            narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      status,
                      if (hasFilter) const SizedBox(height: 8),
                      if (hasFilter)
                        Align(
                          alignment: Alignment.centerRight,
                          child: clear,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: status),
                      if (hasFilter) const SizedBox(width: 8),
                      if (hasFilter) clear,
                    ],
                  ),
            if (onQuickFilter != null) ...[
              const SizedBox(height: 10),
              _quickFilterChips(),
            ],
          ],
        );
      },
    );
  }
}

/// Horizontally scrollable, sheet-style table of task assignment rows.
///
/// [showCompletionColumns] switches between the Assigned-history layout and the
/// Completed-tasks layout. Long descriptions are truncated in the cell and can
/// be expanded inline (no popup) by tapping the row.
class TaskAssignmentTable extends StatefulWidget {
  final List<TaskAssignmentRow> rows;
  final bool showCompletionColumns;

  const TaskAssignmentTable({
    super.key,
    required this.rows,
    this.showCompletionColumns = false,
  });

  @override
  State<TaskAssignmentTable> createState() => _TaskAssignmentTableState();
}

class _TaskAssignmentTableState extends State<TaskAssignmentTable> {
  final Set<String> _expanded = <String>{};

  String _rowKey(TaskAssignmentRow r, int i) =>
      r.assignmentId.isNotEmpty ? r.assignmentId : '${r.taskId}#${r.employeeId}#$i';

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: kTaskPrimaryDark,
  );

  static const TextStyle _cellStyle = TextStyle(
    fontSize: 12.5,
    color: Color(0xFF333333),
  );

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: kTaskPrimaryDark,
  );

  Widget _h(String label, double width) => SizedBox(
        width: width,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _headerStyle,
        ),
      );

  Widget _c(String value, double width, {FontWeight? weight, int maxLines = 2}) =>
      SizedBox(
        width: width,
        child: Text(
          value.trim().isEmpty ? '-' : value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: _cellStyle.copyWith(fontWeight: weight),
        ),
      );

  Widget _statusChip(String status, {double? width}) {
    final color = taskStatusColor(status);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        taskStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
    return width == null ? chip : SizedBox(width: width, child: chip);
  }

  Widget _proofButton(BuildContext context, TaskAssignmentRow r) {
    if (!r.hasProof) {
      return const Text('-', style: _cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return TextButton(
      onPressed: () => openTaskProof(context, r.taskId, r.employeeId),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: kTaskPrimaryDark,
      ),
      child: const Text(
        'View',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _kv(String label, String value, {int maxLines = 3}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: const Text(
          'No records found.',
          style: TextStyle(color: Color(0xFF777777), fontSize: 13),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return isMobile
            ? _buildMobileList()
            : _buildDesktopTable(constraints);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Mobile: stacked sheet-style cards (no horizontal scrolling, no overflow).
  // -------------------------------------------------------------------------
  Widget _buildMobileList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.rows.asMap().entries.map((e) {
        return _buildMobileCard(e.value, e.key);
      }).toList(),
    );
  }

  Widget _buildMobileCard(TaskAssignmentRow r, int i) {
    final completed = widget.showCompletionColumns;
    final key = _rowKey(r, i);
    final isOpen = _expanded.contains(key);

    return InkWell(
      onTap: () => setState(() {
        if (isOpen) {
          _expanded.remove(key);
        } else {
          _expanded.add(key);
        }
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: i.isEven ? Colors.white : const Color(0xFFFCFBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(r.status),
                const SizedBox(width: 4),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: kTaskPrimaryDark,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (completed) ...[
              _kv('Completed Date', formatTaskDate(r.completedAt)),
              _kv('Completed Time', formatTaskTime(r.completedAt)),
            ],
            _kv('Assigned Date', formatTaskDate(r.assignedAt)),
            _kv('Emp ID', r.employeeId),
            _kv('Employee', r.employeeName),
            _kv('Description', r.description, maxLines: 4),
            _kv('Due Date', formatTaskDate(r.dueDate)),
            if (completed) _kv('Proof', r.hasProof ? 'Available' : '-'),
            if (completed && r.hasProof)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => openTaskProof(context, r.taskId, r.employeeId),
                  icon: const Icon(Icons.attachment, size: 17),
                  label: const Text('View Proof', style: TextStyle(fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: kTaskPrimaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            _kv('Assigned By', r.assignedBy),
            if (isOpen) ...[
              const Divider(height: 16),
              _kv('Task ID', r.taskId),
              _kv('Full Description', r.description, maxLines: 100),
              if (r.completionNote.trim().isNotEmpty)
                _kv('Completion Note', r.completionNote),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Desktop/Tablet: horizontally scrollable table.  Rows are rendered as a
  // plain Column (not a ListView) so the outer vertical scroll can handle many
  // rows without an unbounded-height ListView inside a horizontal scroll.
  // -------------------------------------------------------------------------
  Widget _buildDesktopTable(BoxConstraints constraints) {
    const wDate = 92.0;
    const wEmpId = 88.0;
    const wEmpName = 130.0;
    const wTitle = 140.0;
    const wDesc = 200.0;
    const wStatus = 104.0;
    const wProof = 76.0;

    final completed = widget.showCompletionColumns;

    final totalWidth = completed
        ? wDate + wDate + wEmpId + wEmpName + wTitle + wDesc + wDate + wDate + wStatus + wProof
        : wDate + wEmpId + wEmpName + wTitle + wDesc + wDate + wStatus + wEmpName;

    final viewportWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : totalWidth;
    final tableWidth = totalWidth < viewportWidth ? viewportWidth : totalWidth;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _desktopHeader(completed, wDate, wEmpId, wEmpName, wTitle, wDesc, wStatus, wProof),
              ...widget.rows.asMap().entries.map((e) {
                return _desktopRow(e.value, e.key, completed, wDate, wEmpId, wEmpName, wTitle, wDesc, wStatus, wProof);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopHeader(
    bool completed,
    double wDate,
    double wEmpId,
    double wEmpName,
    double wTitle,
    double wDesc,
    double wStatus,
    double wProof,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: kTaskHeaderBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: completed
            ? [
                _h('Completed', wDate),
                _h('Time', wDate),
                _h('Emp ID', wEmpId),
                _h('Employee', wEmpName),
                _h('Task Title', wTitle),
                _h('Description', wDesc),
                _h('Assigned', wDate),
                _h('Due Date', wDate),
                _h('Status', wStatus),
                _h('Proof', wProof),
              ]
            : [
                _h('Assigned', wDate),
                _h('Emp ID', wEmpId),
                _h('Employee', wEmpName),
                _h('Task Title', wTitle),
                _h('Description', wDesc),
                _h('Due Date', wDate),
                _h('Status', wStatus),
                _h('Assigned By', wEmpName),
              ],
      ),
    );
  }

  Widget _desktopRow(
    TaskAssignmentRow r,
    int i,
    bool completed,
    double wDate,
    double wEmpId,
    double wEmpName,
    double wTitle,
    double wDesc,
    double wStatus,
    double wProof,
  ) {
    final key = _rowKey(r, i);
    final isOpen = _expanded.contains(key);

    return InkWell(
      onTap: () => setState(() {
        if (isOpen) {
          _expanded.remove(key);
        } else {
          _expanded.add(key);
        }
      }),
      child: Container(
        color: i.isEven ? Colors.white : const Color(0xFFFCFBFF),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: completed
                  ? [
                      _c(formatTaskDate(r.completedAt), wDate, weight: FontWeight.w600),
                      _c(formatTaskTime(r.completedAt), wDate),
                      _c(r.employeeId, wEmpId, weight: FontWeight.w700),
                      _c(r.employeeName, wEmpName),
                      _c(r.title, wTitle, weight: FontWeight.w600),
                      _c(r.description, wDesc),
                      _c(formatTaskDate(r.assignedAt), wDate),
                      _c(formatTaskDate(r.dueDate), wDate),
                      _statusChip(r.status, width: wStatus),
                      SizedBox(width: wProof, child: _proofButton(context, r)),
                    ]
                  : [
                      _c(formatTaskDate(r.assignedAt), wDate, weight: FontWeight.w600),
                      _c(r.employeeId, wEmpId, weight: FontWeight.w700),
                      _c(r.employeeName, wEmpName),
                      _c(r.title, wTitle, weight: FontWeight.w600),
                      _c(r.description, wDesc),
                      _c(formatTaskDate(r.dueDate), wDate),
                      _statusChip(r.status, width: wStatus),
                      _c(r.assignedBy, wEmpName),
                    ],
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _kv('Task ID', r.taskId),
                    _kv('Full Description', r.description, maxLines: 100),
                    if (r.completionNote.trim().isNotEmpty)
                      _kv('Completion Note', r.completionNote),
                    if (!completed && r.isCompleted)
                      _kv('Completed On', '${formatTaskDate(r.completedAt)} ${formatTaskTime(r.completedAt)}'),
                    if (!completed && r.hasProof)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton.icon(
                          onPressed: () => openTaskProof(context, r.taskId, r.employeeId),
                          icon: const Icon(Icons.attachment, size: 17),
                          label: const Text('View Proof', style: TextStyle(fontSize: 12.5)),
                          style: TextButton.styleFrom(
                            foregroundColor: kTaskPrimaryDark,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Applies the shared search / status / date-range filters to [rows].
List<TaskAssignmentRow> filterTaskRows({
  required List<TaskAssignmentRow> rows,
  required String search,
  required String status,
  required DateTime? fromDate,
  required DateTime? toDate,
  required bool useCompletedDate,
}) {
  final q = search.trim().toLowerCase();

  return rows.where((r) {
    if (q.isNotEmpty) {
      final matches = r.employeeId.toLowerCase().contains(q) ||
          r.employeeName.toLowerCase().contains(q) ||
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      if (!matches) return false;
    }

    if (status != 'All' && taskStatusLabel(r.status) != status) return false;

    if (fromDate != null || toDate != null) {
      final day = taskDateOnly(useCompletedDate ? r.completedAt : r.assignedAt);
      if (day == null) return false;
      if (fromDate != null && day.isBefore(fromDate)) return false;
      if (toDate != null && day.isAfter(toDate)) return false;
    }

    return true;
  }).toList();
}

/// Dedicated Completed Tasks page — replaces the old "Company Tasks" popup.
class AdminCompletedTasksPage extends StatefulWidget {
  const AdminCompletedTasksPage({super.key});

  @override
  State<AdminCompletedTasksPage> createState() =>
      _AdminCompletedTasksPageState();
}

class _AdminCompletedTasksPageState extends State<AdminCompletedTasksPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<TaskAssignmentRow> _rows = [];
  bool _loading = false;
  String? _error;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await fetchTaskAssignmentRows();
      final done = all.where((r) => r.isCompleted).toList();
      // Latest completed task first.
      done.sort((a, b) {
        final ad = DateTime.tryParse(a.completedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = DateTime.tryParse(b.completedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      if (!mounted) return;
      setState(() => _rows = done);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  void _applyQuickFilter(String range) {
    final rangeData = quickDateRange(range);
    if (rangeData == null) return;
    setState(() {
      _fromDate = rangeData.from;
      _toDate = rangeData.to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterTaskRows(
      rows: _rows,
      search: _searchCtrl.text,
      status: 'All',
      fromDate: _fromDate,
      toDate: _toDate,
      useCompletedDate: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: kTaskPrimary,
        elevation: 0,
        title: const Text(
          'Completed Tasks',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6FF), Color(0xFFE8E4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed Tasks (${visible.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 14),
                TaskHistoryFilterBar(
                  searchController: _searchCtrl,
                  statusFilter: 'All',
                  statusOptions: const ['All'],
                  fromDate: _fromDate,
                  toDate: _toDate,
                  dateLabel: 'Completed',
                  onStatusChanged: (_) {},
                  onSearchChanged: (_) => setState(() {}),
                  onPickFromDate: () => _pickDate(isFrom: true),
                  onPickToDate: () => _pickDate(isFrom: false),
                  onClear: () => setState(() {
                    _searchCtrl.clear();
                    _fromDate = null;
                    _toDate = null;
                  }),
                  onQuickFilter: _applyQuickFilter,
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  )
                else
                  TaskAssignmentTable(
                    rows: visible,
                    showCompletionColumns: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}