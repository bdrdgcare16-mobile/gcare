// lib/Pagesusers/my_tasks_page.dart
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

final String _apiBase = ApiService.baseUrl;

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
    this.createdBy,
    this.kind,
    this.completedAt,
    this.completionNote,
    this.proofFileUrl,
  });

  factory _TaskItem.fromJson(Map<String, dynamic> j) => _TaskItem(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Task').toString(),
        description: (j['description'] ?? '').toString(),
        audience: (j['audience'] ?? 'all').toString(),
        status: (j['status'] ?? 'assigned').toString(),
        assignedTo: j['assignedTo']?.toString(),
        dueDate: j['dueDate']?.toString(),
        createdAt: j['createdAt']?.toString(),
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

    final token = CompanyData.token ?? '';

    // Extract role and companyId from profile data
    String? role = '';
    String? companyId = '';
    try {
      if (CompanyData.employeeProfile != null) {
        final profile = CompanyData.employeeProfile as Map<String, dynamic>?;
        role = profile?['role']?.toString() ?? '';
        companyId = profile?['companyId']?.toString() ?? '';
      }
    } catch (e) {
      _log('[MyTasks] Error extracting profile data');
    }

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

        out.sort((a, b) {
          final ad = DateTime.tryParse(a.createdAt ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse(b.createdAt ?? '') ??
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

  // ---------- helpers for dialog ----------

  String _formatISTDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '-';
    DateTime parsed;
    try {
      parsed = DateTime.parse(iso);
    } catch (_) {
      return iso;
    }
    final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    String two(int n) => n.toString().padLeft(2, '0');
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
    final hour12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
    final ampm = ist.hour >= 12 ? 'PM' : 'AM';
    return '${two(ist.day)} ${months[ist.month - 1]} ${ist.year}, '
        '${two(hour12)}:${two(ist.minute)} $ampm';
  }

  // Label bold, value normal, consistent left alignment
  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A4B81),
                letterSpacing: 0.2,
              )),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Upload (DailyUpdate) flow ----

  Future<void> _postDailyUpdate(String description) async {
    if (_posting) return;
    _posting = true;
    // server derives empid from JWT; no client empid needed
    final uri = Uri.parse('${ApiService.baseUrl}/tasks/daily-update');
    final body = jsonEncode({
      'title': 'Daily Update',
      'description': description,
      'dueDate': null,
    });

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if ((CompanyData.token ?? '').isNotEmpty)
            'Authorization': 'Bearer ${CompanyData.token}',
        },
        body: body,
      );

      debugPrint('[MyTasks] Daily update status: ${resp.statusCode}');

      if (!mounted) return;

      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily update posted')),
        );
        await _fetchTasks(); // Refresh assigned tasks
        // Note: Daily updates are fetched from GET /tasks/user, so _fetchTasks() should refresh them
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Post failed (${resp.statusCode}): ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post error: $e')),
      );
    } finally {
      _posting = false;
    }
  }

  // ---- Task completion (proof upload) flow ----

  /// Marks [t] as completed on the backend, optionally attaching [proofFile]
  /// as proof. The backend derives empid/companyId from the JWT and decides
  /// recipient admins server-side — this call only carries the task id,
  /// description, and file.
  Future<void> _completeTask(
    _TaskItem t,
    String description,
    PlatformFile? proofFile,
  ) async {
    if (_posting) return;
    _posting = true;

    final uri = Uri.parse('${ApiService.baseUrl}/tasks/${t.id}/complete');
    final token = (CompanyData.token ?? '').trim();

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

  void _openTaskDetails(_TaskItem t) {
    final status = (t.status).toLowerCase();
    final isCompleted = status == 'completed';
    final isDailyUpdate = (t.kind ?? '').toLowerCase() == 'dailyupdate';
    final canUpload = !isDailyUpdate && !isCompleted;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: kLavenderBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kRoyalPurple, width: 1.4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 14,
                  offset: Offset(0, 6)),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, minHeight: 220),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Task Details',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kRoyalPurple,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else if (canUpload)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRoyalPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload'),
                          onPressed: () => _showUploadBox(t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0x226B4EA2)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kvRow('Title', t.title),
                          _kvRow('Description',
                              t.description.isNotEmpty ? t.description : '-'),
                          if ((t.dueDate ?? '').isNotEmpty)
                            _kvRow('Due Date', t.dueDate!),
                          _kvRow('Created By', 'Admin'),
                          _kvRow('Created At', _formatISTDateTime(t.createdAt)),
                          _kvRow('Status',
                              t.status.isNotEmpty ? t.status : 'Assigned'),
                          if (isCompleted) ...[
                            if ((t.completedAt ?? '').isNotEmpty)
                              _kvRow('Completed At',
                                  _formatISTDateTime(t.completedAt)),
                            if ((t.completionNote ?? '').isNotEmpty)
                              _kvRow('Completion Note', t.completionNote!),
                            _kvRow(
                                'Proof',
                                (t.proofFileUrl ?? '').isNotEmpty
                                    ? 'Uploaded'
                                    : 'Not uploaded'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: kRoyalPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    // Last-line-of-defense: if the backend or local state ever returns a task
    // whose status does not match the selected tab, do not render it here.
    final filtered = _tasks
        .where((t) => t.status.toLowerCase() == status.toLowerCase())
        .toList();

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : filtered.isEmpty
                ? Center(
                    child: Text('No ${status.toLowerCase()} tasks available'))
                : ListView.separated(
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: 800,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      return ListTile(
                        leading: Icon(
                          t.audience == 'all'
                              ? Icons.campaign
                              : Icons.assignment_ind,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          t.title.isNotEmpty ? t.title : 'Task',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.description.isNotEmpty)
                              Text(
                                t.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if ((t.createdAt ?? '').trim().isNotEmpty)
                              Text(_formatISTDateTime(t.createdAt)),
                          ],
                        ),
                        onTap: () => _openTaskDetails(t),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor: Colors.white,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _tasks.length,
                  );
  }
}
