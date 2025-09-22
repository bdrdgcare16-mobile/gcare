// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:file_picker/file_picker.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:serv_app/html_stub.dart'
//   if (dart.library.html) 'package:serv_app/html_web.dart' as html;
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // ⬇️ for auth token you already use elsewhere (e.g., LiveAttendancePage)
// import 'package:serv_app/models/company_data.dart';

// class MyTasksPage extends StatefulWidget {
//   const MyTasksPage({super.key});

//   @override
//   State<MyTasksPage> createState() => _MyTasksPageState();
// }

// class _MyTasksPageState extends State<MyTasksPage> {
//   // API base
//   static const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

//   // local preview list (unchanged UI)
//   List<PlatformFile> uploadedFiles = [];

//   // daily updates (now filled from API)
//   List<Map<String, dynamic>> dailyUpdates = [];
//   bool isLoadingUpdates = false;

//   final bool _isUploading = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchDailyUpdates(); // now calls API instead of dummy data
//   }

//   /// Turn a possibly-relative `/uploads/...` into absolute URL
//   String? _absUrl(dynamic maybeUrl) {
//     if (maybeUrl == null) return null;
//     final u = maybeUrl.toString();
//     return u.startsWith('http') ? u : '$_apiBase$u';
//   }

//   /// ⬇️ CHANGED: Pull real daily updates from backend and map to your dialog shape
//   Future<void> fetchDailyUpdates() async {
//     setState(() => isLoadingUpdates = true);

//     try {
//       // If your backend supports `?kind=DailyUpdate`, you can use that.
//       // To be fully compatible, we fetch broadcasts and filter on the client.
//       final uri = Uri.parse('$_apiBase/api/tasks?audience=all');

//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//       };
//       final token = CompanyData.token;
//       if (token != null && token.isNotEmpty) {
//         headers['Authorization'] = 'Bearer $token';
//       }

//       final resp = await http.get(uri, headers: headers);

//       if (resp.statusCode == 200) {
//         final List<dynamic> list = jsonDecode(resp.body);

//         // only keep DailyUpdate docs
//         final daily = list.where((e) {
//           final kind = (e['kind'] ?? '').toString();
//           return kind.toLowerCase() == 'dailyupdate';
//         }).toList();

//         // sort newest first by createdAt
//         daily.sort((a, b) {
//           final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           return bd.compareTo(ad);
//         });

//         // map to the dialog shape you already use
//         final mapped = daily.map<Map<String, dynamic>>((e) {
//           final file = (e['file'] is Map<String, dynamic>) ? e['file'] : null;
//           final title = (e['title'] ?? file?['name'] ?? 'Daily update').toString();
//           final createdAt = (e['createdAt'] ?? '').toString();
//           final date = createdAt.isNotEmpty && createdAt.contains('T')
//               ? createdAt.split('T').first
//               : createdAt;

//           return {
//             "date": date,
//             "update": title,
//             "timeSpent": "", // not stored; leave blank
//             "updatedBy": (e['createdBy'] ?? e['assignedTo'] ?? '').toString(),
//             "file": _absUrl(file != null ? file['url'] : null),
//           };
//         }).toList();

//         setState(() {
//           dailyUpdates = mapped;
//           isLoadingUpdates = false;
//         });
//       } else {
//         setState(() {
//           isLoadingUpdates = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch updates: ${resp.statusCode}')),
//         );
//       }
//     } catch (e) {
//       setState(() => isLoadingUpdates = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to fetch updates: $e')),
//       );
//     }
//   }

//   /// Pick file for "Task assigned" and upload to backend (no UI changes)
//   Future<void> pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       withData: kIsWeb, // web needs bytes
//     );
//     if (result == null) return;

//     final PlatformFile picked = result.files.single;

//     // this page is for admin; keeping existing behavior (local dialog add)
//     setState(() => uploadedFiles.add(picked));
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('✅ File selected.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   void showUploadedFiles(List<PlatformFile> files, String title) {
//     showDialog(
//       context: context,
//       builder: (_) => TaskUploadsDialog(files: files, title: title),
//     );
//   }

//   void showDailyUpdateDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text("Daily Updates", style: TextStyle(fontWeight: FontWeight.bold)),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: isLoadingUpdates
//               ? const Center(child: CircularProgressIndicator())
//               : dailyUpdates.isEmpty
//                   ? const Text("No daily updates yet.")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: dailyUpdates.length,
//                       itemBuilder: (ctx, index) {
//                         final update = dailyUpdates[index];
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             title: Text("📅 ${update['date']}"),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text("📝 ${update['update']}"),
//                                 if ((update['timeSpent'] as String).isNotEmpty)
//                                   Text("⏱ ${update['timeSpent']}"),
//                                 if ((update['updatedBy'] as String).isNotEmpty)
//                                   Text("👩‍💻 ${update['updatedBy']}"),
//                               ],
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
//                               onPressed: () {
//                                 final url = update['file'] as String?;
//                                 if (url != null && url.isNotEmpty) {
//                                   _openFileFromURL(url);
//                                 }
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openFileFromURL(String fileUrl) {
//     if (kIsWeb) {
//       html.window.open(fileUrl, "_blank");
//     } else {
//       OpenFilex.open(fileUrl);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF8E71B7),
//         centerTitle: true,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "My Tasks",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//       ),
//       body: Container(
//         height: double.infinity,
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Color(0xFFD1C4E9)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               taskSection(
//                 "Task assigned",
//                 showUpload: true,
//                 onUpload: _isUploading ? () {} : () => pickFile(),
//                 onView: () => showUploadedFiles(uploadedFiles, "Task Uploads"),
//               ),
//               const SizedBox(height: 30),
//               taskSection(
//                 "Daily Update",
//                 showUpload: false,
//                 onUpload: () {},
//                 onView: showDailyUpdateDialog, // now shows live data
//               ),
//               const SizedBox(height: 30),
//               if (_isUploading)
//                 const Center(
//                   child: Padding(
//                     padding: EdgeInsets.only(top: 8.0),
//                     child: CircularProgressIndicator(),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget taskSection(
//     String title, {
//     required bool showUpload,
//     required VoidCallback onUpload,
//     required VoidCallback onView,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Center(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: const Color(0xFF8E71B7),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (showUpload)
//               ElevatedButton(
//                 onPressed: onUpload,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF6B5E94),
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 child: const Text("Upload", style: TextStyle(color: Colors.white)),
//               ),
//             if (showUpload) const SizedBox(width: 20),
//             ElevatedButton(
//               onPressed: onView,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6B5E94),
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text("View", style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class TaskUploadsDialog extends StatelessWidget {
//   final List<PlatformFile> files;
//   final String title;

//   const TaskUploadsDialog({
//     super.key,
//     required this.files,
//     required this.title,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: files.isEmpty
//             ? const Center(child: Text("No files uploaded"))
//             : ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: files.length,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     leading: const Icon(Icons.insert_drive_file, size: 30),
//                     title: Text(files[index].name),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       if (kIsWeb) {
//                         final fileBytes = files[index].bytes;
//                         final fileName = files[index].name;
//                         if (fileBytes != null) {
//                           final blob = html.Blob([fileBytes]);
//                           final url = html.Url.createObjectUrlFromBlob(blob);
//                           final anchor = html.AnchorElement(href: url)
//                             ..target = '_blank'
//                             ..download = fileName;
//                           anchor.click();
//                           html.Url.revokeObjectUrl(url);
//                         }
//                       } else {
//                         if (files[index].path != null) {
//                           await OpenFilex.open(files[index].path!);
//                         }
//                       }
//                     },
//                   );
//                 },
//               ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
//         )
//       ],
//     );
//   }
// }
// lib/Pagesusers/my_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Auth token you already use elsewhere (e.g., LiveAttendancePage)
import 'package:serv_app/models/company_data.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  // API base
  static const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

  // Daily updates (from API)
  List<Map<String, dynamic>> dailyUpdates = [];
  bool isLoadingUpdates = false;

  // My assigned tasks (audience='employee')
  List<Map<String, dynamic>> myAssigned = [];
  bool isLoadingAssigned = false;

  // Simple "broadcast task" form (TEXT ONLY now)
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate; // optional

  @override
  void initState() {
    super.initState();
    fetchDailyUpdates();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// Fetch daily updates (unchanged logic, still reads from /api/tasks?audience=all)
  Future<void> fetchDailyUpdates() async {
    setState(() => isLoadingUpdates = true);
    try {
      final uri = Uri.parse('$_apiBase/tasks?audience=all');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = CompanyData.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);
        final daily = list.where((e) {
          final kind = (e['kind'] ?? '').toString();
          return kind.toLowerCase() == 'dailyupdate';
        }).toList();

        daily.sort((a, b) {
          final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        final mapped = daily.map<Map<String, dynamic>>((e) {
          final title = (e['title'] ?? 'Daily update').toString();
          final createdAt = (e['createdAt'] ?? '').toString();
          final date =
              createdAt.contains('T') ? createdAt.split('T').first : createdAt;

          return {
            "date": date,
            "update": title,
            "updatedBy": (e['createdBy'] ?? e['assignedTo'] ?? '').toString(),
          };
        }).toList();

        setState(() {
          dailyUpdates = mapped;
          isLoadingUpdates = false;
        });
      } else {
        setState(() => isLoadingUpdates = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch updates: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoadingUpdates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch updates: $e')),
      );
    }
  }

  /// Create a BROADCAST task (text-only)
  Future<void> _createBroadcastTask() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse('$_apiBase/tasks/broadcast');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = CompanyData.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "dueDate": _dueDate == null ? null : _fmtDate(_dueDate!),
      "kind": "Task"
    };

    try {
      final resp =
          await http.post(uri, headers: headers, body: jsonEncode(body));
      if (resp.statusCode == 201) {
        _titleCtrl.clear();
        _descCtrl.clear();
        setState(() => _dueDate = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showDailyUpdateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Updates",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoadingUpdates
              ? const Center(child: CircularProgressIndicator())
              : dailyUpdates.isEmpty
                  ? const Text("No daily updates yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: dailyUpdates.length,
                      itemBuilder: (ctx, i) {
                        final u = dailyUpdates[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text("📅 ${u['date']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📝 ${u['update']}"),
                                if ((u['updatedBy'] as String).isNotEmpty)
                                  Text("👩‍💻 ${u['updatedBy']}"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Close", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  /// Fetch tasks assigned to this employee (audience='employee')
  Future<void> fetchMyAssignedTasks() async {
    setState(() => isLoadingAssigned = true);
    try {
      // ✅ Always call /tasks/employee; include empid if available
      final empid = (CompanyData.empid ?? '').trim();
      final uri = Uri.parse(empid.isNotEmpty
          ? '$_apiBase/tasks/employee?empid=${Uri.encodeQueryComponent(empid)}'
          : '$_apiBase/tasks/employee');

      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = CompanyData.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);

        // Ensure only personal tasks (server already filters, this is a safety net)
        final personal = list.where((e) {
          final audience = (e['audience'] ?? '').toString().toLowerCase();
          if (audience != 'employee') return false;
          if (empid.isEmpty) return true;
          return (e['assignedTo'] ?? '').toString().trim() == empid;
        }).toList();

        personal.sort((a, b) {
          final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        final mapped = personal.map<Map<String, dynamic>>((e) {
          final createdAt = (e['createdAt'] ?? '').toString();
          final date =
              createdAt.contains('T') ? createdAt.split('T').first : createdAt;
          return {
            "title": (e['title'] ?? 'Task').toString(),
            "description": (e['description'] ?? '').toString(),
            "dueDate": (e['dueDate'] ?? '').toString(),
            "createdAt": date,
            "kind": (e['kind'] ?? '').toString(),
          };
        }).toList();

        setState(() {
          myAssigned = mapped;
          isLoadingAssigned = false;
        });
      } else {
        setState(() => isLoadingAssigned = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to fetch assigned tasks: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoadingAssigned = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch assigned tasks: $e')),
      );
    }
  }

  // Dialog to show assigned tasks
  void showAssignedTasksDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "My Assigned Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoadingAssigned
              ? const Center(child: CircularProgressIndicator())
              : myAssigned.isEmpty
                  ? const Text("No assigned tasks yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: myAssigned.length,
                      itemBuilder: (ctx, i) {
                        final t = myAssigned[i];
                        final hasDue =
                            (t['dueDate'] as String).trim().isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(t['title'] as String),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((t['description'] as String).isNotEmpty)
                                  Text(t['description'] as String),
                                Text("Assigned on: ${t['createdAt']}"),
                                if (hasDue) Text("Due: ${t['dueDate']}"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Close", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E71B7),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Tasks",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ======= Task assigned (Broadcast): TEXT ONLY =======
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E71B7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Task assigned",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Description (requested single description box)
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Optional due date + Submit
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _dueDate == null
                                  ? 'Pick due date (optional)'
                                  : 'Due: ${_fmtDate(_dueDate!)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _createBroadcastTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5E94),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Submit",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ======= Daily Update header (kept) + View button shows assigned tasks =======
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E71B7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Daily Update",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                // On click: fetch personal tasks and show them
                onPressed: () async {
                  await fetchMyAssignedTasks();
                  if (!mounted) return;
                  showAssignedTasksDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5E94),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child:
                    const Text("View", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
