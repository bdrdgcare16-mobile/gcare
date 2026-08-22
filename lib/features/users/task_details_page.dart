// lib/features/users/task_details_page.dart
//
// Opened when the user taps a TASK_ASSIGNED push/local notification.
//
// SECURITY: the notification payload (type/entityType/entityId) is only used
// for navigation. It is NEVER trusted as authorization. This screen always
// re-fetches the task from the authenticated backend API, which re-verifies
// that the current user is allowed to see it (same company + assigned
// employee or admin) before returning any data.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:serv_app/services/api_service.dart';

const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);

class TaskDetailsPage extends StatefulWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _task;

  @override
  void initState() {
    super.initState();
    _fetchTask();
  }

  Future<void> _fetchTask() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Always fetch from the authenticated backend API — the backend
      // re-verifies company + assignment/role before returning the task.
      final resp = await ApiService.get('/tasks/${widget.taskId}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _task = data;
          _loading = false;
        });
      } else if (resp.statusCode == 403) {
        if (!mounted) return;
        setState(() {
          _error = 'You are not authorized to view this task.';
          _loading = false;
        });
      } else if (resp.statusCode == 404) {
        if (!mounted) return;
        setState(() {
          _error = 'This task no longer exists.';
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to load task (${resp.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load task: $e';
        _loading = false;
      });
    }
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A4B81),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text('Task Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTask,
                          style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kvRow('Title', (_task?['title'] ?? '').toString()),
                      _kvRow('Description', (_task?['description'] ?? '').toString()),
                      _kvRow('Due date', (_task?['dueDate'] ?? '').toString()),
                      _kvRow('Status', (_task?['status'] ?? '').toString()),
                      if (((_task?['status'] ?? '').toString().toLowerCase()) == 'completed') ...[
                        _kvRow('Completed At', (_task?['completedAt'] ?? '').toString()),
                        _kvRow('Completion Note', (_task?['completionNote'] ?? '').toString()),
                        _kvRow('Proof', ((_task?['proofFileUrl'] ?? '').toString()).isNotEmpty ? 'Uploaded' : 'Not uploaded'),
                      ],
                    ],
                  ),
                ),
    );
  }
}
