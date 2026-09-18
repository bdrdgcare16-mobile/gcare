import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/models/company_data.dart';
import 'package:flutter/foundation.dart';
import 'package:serv_app/services/api_service.dart';

void _log(Object msg) {
  if (kDebugMode) {
    print(msg);
  }
}


const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// Dialog theme
const Color kLavenderBg = Color(0xFFF3E8FF);
const Color kRoyalPurple = Color(0xFF6B4EA2);

/* ---------- SIMPLE TASK MODEL (no files) ---------- */
class _TaskItem {
  final String id;
  final String title;
  final String description;
  final String audience; // "all" | "employee"
  final String? assignedTo; // empid when audience='employee'
  final String? dueDate; // ISO or yyyy-MM-dd
  final String? createdAt; // ISO string
  final String? assignedAt; // ISO string (real assignment timestamp)
  final String? createdBy; // uid/userId
  final String? kind; // "Task" | "DailyUpdate" | etc.
  final String status; // "assigned" | "completed" | "in_progress"
  final String? completedAt; // ISO string
  final String? completionNote;
  final String? proofFileUrl;

  _TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.audience,
    required this.status,
    this.assignedTo,
    this.dueDate,
    this.createdAt,
    this.assignedAt,
    this.createdBy,
    this.kind,
    this.completedAt,
    this.completionNote,
    this.proofFileUrl,
  });

  /// Real assignment timestamp from `taskAssignments.assignedAt`, falling back
  /// to the task creation timestamp for legacy tasks. Never derived from
  /// the due date.
  String? get assignedDate =>
      (assignedAt ?? '').trim().isNotEmpty ? assignedAt : createdAt;

  factory _TaskItem.fromJson(Map<String, dynamic> j) => _TaskItem(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Task').toString(),
        description: (j['description'] ?? '').toString(),
        audience: (j['audience'] ?? 'all').toString(),
        status: (j['status'] ?? 'assigned').toString(),
        assignedTo: j['assignedTo']?.toString(),
        dueDate: j['dueDate']?.toString(),
        createdAt: j['createdAt']?.toString(),
        assignedAt: j['assignedAt']?.toString(),
        createdBy: j['createdBy']?.toString(),
        kind: j['kind']?.toString(),
        completedAt: j['completedAt']?.toString(),
        completionNote: j['completionNote']?.toString(),
        proofFileUrl: j['proofFileUrl']?.toString(),
      );
}

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});
  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  bool _isFetching = false;
  List<_TaskItem> _tasks = [];
  bool _posting = false;
  final Set<String> _expandedRows = <String>{};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchTasks();
      }
    });
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() {
      _loading = true;
      _error = null;
    });

    // Get status based on selected tab
    final status = _tabController.index == 0 ? 'assigned' : 'completed';

    // merged view (broadcast + personal)
    final uri =
        Uri.parse('${ApiService.baseUrl}/tasks/user?status=$status&limit=50');

    final token = CompanyData.token;

    try {
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      _log('[MyTasks] response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);
        final out = list
            .map((e) => _TaskItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // Hide self-posted daily updates; they are not actionable tasks.
        out.removeWhere((t) =>
            (t.kind ?? '').toLowerCase().replaceAll(' ', '') == 'dailyupdate');

        // Completed tab sorts by completed date; assigned tab by assigned date.
        out.sort((a, b) {
          if (status == 'completed') {
            final ad = DateTime.tryParse(a.completedAt ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bd = DateTime.tryParse(b.completedAt ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          }
          final ad = DateTime.tryParse(a.assignedDate ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse(b.assignedDate ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        if (!mounted) return;
        setState(() => _tasks = out);
      } else {
        if (!mounted) return;
        setState(() => _error = 'Error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      _log('[MyTasks] Exception occurred');
      if (e is FormatException) {
        setState(() => _error = 'Failed to parse response: ${e.message}');
      } else if (e.toString().contains('timeout')) {
        setState(() => _error = 'Request timed out');
      } else if (e.toString().contains('SocketException')) {
        setState(() => _error = 'Network error - please check connection');
      } else {
        setState(() => _error = 'Failed to fetch tasks: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _isFetching = false;
    }
  }

  /// `01 Sep 2026` in IST. Plain yyyy-MM-dd values (dueDate) are not shifted.
  String _formatTableDate(String? iso) {
    final v = (iso ?? '').trim();
    if (v.isEmpty) return '-';

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

    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (dateOnly != null) {
      final m = int.tryParse(dateOnly.group(2)!) ?? 1;
      return '${dateOnly.group(3)} ${months[(m - 1).clamp(0, 11)]} '
          '${dateOnly.group(1)}';
    }

    final parsed = DateTime.tryParse(v);
    if (parsed == null) return v;
    final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.day.toString().padLeft(2, '0')} '
        '${months[ist.month - 1]} ${ist.year}';
  }

  /// Friendly label for the existing backend status values.
  String _statusLabel(String raw) {
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

  Color _statusColor(String raw) {
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

  // ---- Task completion (proof upload) flow ----

  /// Marks [t] as completed on the backend, optionally attaching [proofFile]
  /// as proof. The backend derives empid/companyId from the JWT and decides
  /// recipient admins server-side â€” this call only carries the task id,
  /// description, and file.
  Future<void> _completeTask(
    _TaskItem t,
    String description,
    PlatformFile? proofFile,
  ) async {
    if (_posting) return;
    _posting = true;

    final uri = Uri.parse('${ApiService.baseUrl}/tasks/${t.id}/complete');
    final token = CompanyData.token.trim();

    _log('[CompleteTask] Has file: ${proofFile != null}');

    try {
      http.Response resp;

      // Case 1: No file - send regular JSON request
      if (proofFile == null) {
        _log('[CompleteTask] Sending JSON request');
        resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'description': description}),
        );
      }
      // Case 2: With file - send multipart request
      else {
        _log('[CompleteTask] Sending multipart request');
        final request = http.MultipartRequest('POST', uri);

        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['description'] = description;

        // Add file if available
        if (proofFile.bytes != null && proofFile.bytes!.isNotEmpty) {
          _log('[CompleteTask] Adding file from bytes');
          request.files.add(
            http.MultipartFile.fromBytes(
              'proof',
              proofFile.bytes!,
              filename: proofFile.name,
            ),
          );
        } else if (!kIsWeb &&
            proofFile.path != null &&
            proofFile.path!.isNotEmpty) {
          _log('[CompleteTask] Adding file from path');
          request.files.add(
            await http.MultipartFile.fromPath(
              'proof',
              proofFile.path!,
              filename: proofFile.name,
            ),
          );
        }

        _log('[CompleteTask] Fields: ${request.fields.length} field(s)');
        _log('[CompleteTask] Files count: ${request.files.length}');

        final streamed = await request.send();
        resp = await http.Response.fromStream(streamed);
      }

      _log('[CompleteTask] status: ${resp.statusCode}');

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        // Optimistically remove the completed task from the current (Assigned) list
        // before refetching, so the UI updates instantly without a server round-trip.
        if (mounted) {
          setState(() => _tasks.removeWhere((task) => task.id == t.id));
        }
        await _fetchTasks();
      } else if (resp.statusCode == 400 || resp.statusCode == 409) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>?;
        final message =
            (body?['error'] ?? 'This task has already been completed.')
                .toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed (${resp.statusCode}): ${resp.body}')),
        );
      }
    } catch (e) {
      _log('[CompleteTask] Exception occurred');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _posting = false;
    }
  }

  Future<void> _showUploadBox(_TaskItem t) async {
    final controller = TextEditingController();
    PlatformFile? pickedFile;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              color: kLavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kRoyalPurple, width: 1.2),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kRoyalPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A4B81),
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 200, minHeight: 120),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Describe what you completed...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setDialogState(() => pickedFile = result.files.first);
                        }
                      },
                      icon: const Icon(Icons.attach_file, color: kRoyalPurple),
                      label: Text(
                        pickedFile == null
                            ? 'Attach proof (optional)'
                            : pickedFile!.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kRoyalPurple),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel',
                          style: TextStyle(color: kRoyalPurple)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRoyalPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a description')),
                          );
                          return;
                        }
                        Navigator.pop(dialogContext); // close input dialog
                        await _completeTask(t, text, pickedFile);
                      },
                      child: const Text('Mark Completed'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: kAppBarColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTaskList('assigned'),
            _buildTaskList('completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(String status) {
    final filtered = _tasks
        .where((t) => t.status.toLowerCase() == status.toLowerCase())
        .toList();

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (filtered.isEmpty) {
      return Center(child: Text('No ${status.toLowerCase()} tasks available'));
    }

    final completed = status.toLowerCase() == 'completed';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Text(
                '${status[0].toUpperCase()}${status.substring(1)} Tasks (${filtered.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: isMobile
                  ? _buildMobileTaskList(filtered, completed)
                  : _buildDesktopTaskTable(filtered, completed, constraints),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile employee task sheet (cards) — no horizontal scrolling, no overflow.
  // ---------------------------------------------------------------------------
  Widget _buildMobileTaskList(List<_TaskItem> tasks, bool completed) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _buildMobileTaskCard(tasks[i], i, completed),
    );
  }

  Widget _buildMobileTaskCard(_TaskItem t, int i, bool completed) {
    final isOpen = _expandedRows.contains(t.id);
    final isDailyUpdate =
        (t.kind ?? '').toLowerCase().replaceAll(' ', '') == 'dailyupdate';
    final canComplete = !isDailyUpdate && t.status.toLowerCase() != 'completed';

    return InkWell(
      onTap: () => setState(() {
        if (isOpen) {
          _expandedRows.remove(t.id);
        } else {
          _expandedRows.add(t.id);
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
                    t.title,
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
                _employeeStatusChip(t.status),
                const SizedBox(width: 6),
                if (completed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else if (canComplete)
                  SizedBox(
                    width: 68,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _showUploadBox(t),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: const Text(
                        'Upload',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.expand_more,
                      size: 18, color: kRoyalPurple),
              ],
            ),
            const SizedBox(height: 10),
            if (completed)
              _taskKv('Completed', _formatTableDate(t.completedAt)),
            _taskKv('Assigned', _formatTableDate(t.assignedDate)),
            _taskKv('Description', t.description, maxLines: 4),
            _taskKv('Due Date', _formatTableDate(t.dueDate)),
            _taskKv('Status', _statusLabel(t.status)),
            if (completed && (t.completionNote ?? '').isNotEmpty)
              _taskKv('Completion Note', t.completionNote!),
            if (isOpen) ...[
              const Divider(height: 16),
              _taskKv('Task ID', t.id),
              _taskKv('Full Description', t.description, maxLines: 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _taskKv(String label, String value, {int maxLines = 3}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kRoyalPurple,
            ),
          ),
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

  Widget _employeeStatusChip(String raw) {
    final color = _statusColor(raw);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(raw),
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
  }

  // ---------------------------------------------------------------------------
  // Desktop employee task table — horizontally scrollable with fixed columns.
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTaskTable(
    List<_TaskItem> tasks,
    bool completed,
    BoxConstraints constraints,
  ) {
    const headerBg = Color(0xFFEDE7F6);
    const wDate = 92.0;
    const wTitle = 130.0;
    const wDesc = 180.0;
    const wDue = 92.0;
    const wStatus = 95.0;
    const wExpand = 42.0;
    const wAction = 95.0;

    final totalWidth = completed
        ? wDate + wTitle + wDesc + wDate + wDue + wStatus + wExpand
        : wDate + wTitle + wDesc + wDue + wStatus + wExpand + wAction;

    final viewportWidth =
        constraints.maxWidth.isFinite ? constraints.maxWidth : totalWidth;
    final tableWidth = totalWidth < viewportWidth ? viewportWidth : totalWidth;

    Widget h(String label, double width) => SizedBox(
          width: width,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A347F),
            ),
          ),
        );

    Widget c(String value, double width, {FontWeight? weight}) => SizedBox(
          width: width,
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: const Color(0xFF333333),
              fontWeight: weight,
            ),
          ),
        );

    Widget statusChip(String raw) {
      final color = _statusColor(raw);
      return Container(
        width: wStatus,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _statusLabel(raw),
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
    }

    Widget expandIcon(_TaskItem t, bool isOpen) {
      return SizedBox(
        width: wExpand,
        height: 40,
        child: Center(
          child: GestureDetector(
            onTap: () => setState(() {
              if (isOpen) {
                _expandedRows.remove(t.id);
              } else {
                _expandedRows.add(t.id);
              }
            }),
            child: Icon(
              isOpen ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: kRoyalPurple,
            ),
          ),
        ),
      );
    }

    Widget actionCell(_TaskItem t) {
      final isDailyUpdate =
          (t.kind ?? '').toLowerCase().replaceAll(' ', '') == 'dailyupdate';
      final canComplete =
          !isDailyUpdate && t.status.toLowerCase() != 'completed';
      return SizedBox(
        width: wAction,
        height: 34,
        child: canComplete
            ? ElevatedButton(
                onPressed: () => _showUploadBox(t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 10.5),
                ),
                child: const Text(
                  'Upload',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : const Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  color: headerBg,
                  child: Row(
                    children: completed
                        ? [
                            h('Completed', wDate),
                            h('Task', wTitle),
                            h('Description', wDesc),
                            h('Assigned', wDate),
                            h('Due Date', wDue),
                            h('Status', wStatus),
                            h('', wExpand),
                          ]
                        : [
                            h('Assigned', wDate),
                            h('Task', wTitle),
                            h('Description', wDesc),
                            h('Due Date', wDue),
                            h('Status', wStatus),
                            h('', wExpand),
                            h('Action', wAction),
                          ],
                  ),
                ),
                ...tasks.asMap().entries.map((e) {
                  final i = e.key;
                  final t = e.value;
                  final isOpen = _expandedRows.contains(t.id);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    color: i.isEven ? Colors.white : const Color(0xFFFCFBFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: completed
                              ? [
                                  c(_formatTableDate(t.completedAt), wDate,
                                      weight: FontWeight.w600),
                                  c(t.title, wTitle,
                                      weight: FontWeight.w600),
                                  c(t.description, wDesc),
                                  c(_formatTableDate(t.assignedDate), wDate),
                                  c(_formatTableDate(t.dueDate), wDue),
                                  statusChip(t.status),
                                  expandIcon(t, isOpen),
                                ]
                              : [
                                  c(_formatTableDate(t.assignedDate), wDate,
                                      weight: FontWeight.w600),
                                  c(t.title, wTitle,
                                      weight: FontWeight.w600),
                                  c(t.description, wDesc),
                                  c(_formatTableDate(t.dueDate), wDue),
                                  statusChip(t.status),
                                  expandIcon(t, isOpen),
                                  actionCell(t),
                                ],
                        ),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Text(
                                  'Task ID: ${t.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Full Description: ${t.description.isNotEmpty ? t.description : '-'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (completed &&
                                    (t.completionNote ?? '').isNotEmpty)
                                  Text(
                                    'Completion Note: ${t.completionNote}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}