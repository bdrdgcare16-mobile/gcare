// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Auth token you already use elsewhere (e.g., LiveAttendancePage)
// import 'package:serv_app/config/api_config.dart';
// import 'package:serv_app/services/api_service.dart';
// import 'package:serv_app/models/company_data.dart';

// class MyTasksPage extends StatefulWidget {
//   const MyTasksPage({super.key});

//   @override
//   State<MyTasksPage> createState() => _MyTasksPageState();
// }

// class _MyTasksPageState extends State<MyTasksPage> {
//   // API base
//   static final String _apiBase = ApiConfig.baseUrl;

//   // Daily updates (from API)
//   List<Map<String, dynamic>> dailyUpdates = [];
//   bool isLoadingUpdates = false;

//   // My assigned tasks (audience='employee')
//   List<Map<String, dynamic>> myAssigned = [];
//   bool isLoadingAssigned = false;

//   // Simple "broadcast task" form (TEXT ONLY now)
//   final _formKey = GlobalKey<FormState>();
//   final _titleCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();
//   final _empIdCtrl = TextEditingController(); // NEW: for one-employee assignment
//   DateTime? _dueDate; // optional

//   // NEW: dropdown state -> 'all' or 'employee'
//   String _audience = 'all';

//   @override
//   void initState() {
//     super.initState();
//     fetchDailyUpdates();
//   }

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _descCtrl.dispose();
//     _empIdCtrl.dispose();
//     super.dispose();
//   }

//   String _fmtDate(DateTime d) =>
//       "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

//   /// Fetch daily updates from /tasks/user endpoint
//   Future<void> fetchDailyUpdates() async {
//     setState(() => isLoadingUpdates = true);
//     try {
//       final uri = Uri.parse('${ApiService.baseUrl}/tasks/user');
//       final headers = <String, String>{'Content-Type': 'application/json'};
//       final token = CompanyData.token;
//       if (token != null && token.isNotEmpty) {
//         headers['Authorization'] = 'Bearer $token';
//       }

//       final resp = await http.get(uri, headers: headers);
//       if (resp.statusCode == 200) {
//         final List<dynamic> list = jsonDecode(resp.body);
//         final daily = list.where((e) {
//           final kind = (e['kind'] ?? '').toString();
//           return kind.toLowerCase() == 'dailyupdate';
//         }).toList();

//         daily.sort((a, b) {
//           final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           return bd.compareTo(ad);
//         });

//         final mapped = daily.map<Map<String, dynamic>>((e) {
//           final title = (e['title'] ?? 'Daily update').toString();
//           final createdAt = (e['createdAt'] ?? '').toString();
//           final date =
//               createdAt.contains('T') ? createdAt.split('T').first : createdAt;

//           return {
//             "date": date,
//             "update": title,
//             "updatedBy": (e['createdBy'] ?? e['assignedTo'] ?? '').toString(),
//           };
//         }).toList();

//         setState(() {
//           dailyUpdates = mapped;
//           isLoadingUpdates = false;
//         });
//       } else {
//         setState(() => isLoadingUpdates = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to fetch updates: ${resp.statusCode}')),
//           );
//         }
//       }
//     } catch (e) {
//       setState(() => isLoadingUpdates = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch updates: $e')),
//         );
//       }
//     }
//   }

//   /// Create a task:
//   /// - If _audience == 'all': broadcast to everyone
//   /// - If _audience == 'employee': assign only to given empid
//   Future<void> _createBroadcastTask() async {
//     if (!_formKey.currentState!.validate()) return;

//     // Validate empid only when assigning to a single employee
//     if (_audience == 'employee' && _empIdCtrl.text.trim().isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter: employee empid.')),
//         );
//       }
//       return;
//     }

//     final uri = Uri.parse('${ApiService.baseUrl}/tasks/broadcast');
//     final headers = <String, String>{'Content-Type': 'application/json'};
//     final token = CompanyData.token;
//     if (token != null && token.isNotEmpty) {
//       headers['Authorization'] = 'Bearer $token';
//     }

//     final body = {
//       "title": _titleCtrl.text.trim(),
//       "description": _descCtrl.text.trim(),
//       "dueDate": _dueDate == null ? null : _fmtDate(_dueDate!),
//       "kind": "Task",
//       // NEW: audience + (optional) assignedTo
//       "audience": _audience, // 'all' or 'employee'
//       if (_audience == 'employee') "assignedTo": _empIdCtrl.text.trim(),
//     };

//     try {
//       final resp =
//           await http.post(uri, headers: headers, body: jsonEncode(body));
//       if (resp.statusCode == 201) {
//         _titleCtrl.clear();
//         _descCtrl.clear();
//         _empIdCtrl.clear();
//         setState(() => _dueDate = null);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Task created successfully.'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   void showDailyUpdateDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text("User Daily Updates",
//             style: TextStyle(fontWeight: FontWeight.bold)),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: isLoadingUpdates
//               ? const Center(child: CircularProgressIndicator())
//               : dailyUpdates.isEmpty
//                   ? const Text("No assigned tasks yet.")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: dailyUpdates.length,
//                       itemBuilder: (ctx, i) {
//                         final u = dailyUpdates[i];
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             title: Text("📅 ${u['date']}"),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text("📝 ${u['update']}"),
//                                 if ((u['updatedBy'] as String).isNotEmpty)
//                                   Text("👩‍💻 ${u['updatedBy']}"),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close",
//                 style: TextStyle(color: Colors.deepPurple)),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Fetch tasks assigned to this employee (audience='employee')
//   Future<void> fetchMyAssignedTasks() async {
//     setState(() => isLoadingAssigned = true);
//     try {
//       // ✅ Always call /tasks/employee; include empid if available
//       final empid = (CompanyData.empid ?? '').trim();
//       final uri = Uri.parse(empid.isNotEmpty
//           ? '${ApiService.baseUrl}/tasks/employee?empid=${Uri.encodeQueryComponent(empid)}'
//           : '${ApiService.baseUrl}/tasks/employee');

//       final headers = <String, String>{'Content-Type': 'application/json'};
//       final token = CompanyData.token;
//       if (token != null && token.isNotEmpty) {
//         headers['Authorization'] = 'Bearer $token';
//       }

//       final resp = await http.get(uri, headers: headers);
//       if (resp.statusCode == 200) {
//         final List<dynamic> list = jsonDecode(resp.body);

//         // Ensure only personal tasks (server already filters, this is a safety net)
//        final personal = list.where((e) {
//          final audience = (e['audience'] ?? '').toString().toLowerCase();
//          final assignedTo = (e['assignedTo'] ?? '').toString().trim();

//          return audience == 'all' ||
//            (audience == 'employee' && assignedTo == empid);
//       }).toList();

//         personal.sort((a, b) {
//           final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
//               DateTime.fromMillisecondsSinceEpoch(0);
//           return bd.compareTo(ad);
//         });

//         final mapped = personal.map<Map<String, dynamic>>((e) {
//           final createdAt = (e['createdAt'] ?? '').toString();
//           final date =
//               createdAt.contains('T') ? createdAt.split('T').first : createdAt;
//           return {
//             "title": (e['title'] ?? 'Task').toString(),
//             "description": (e['description'] ?? '').toString(),
//             "dueDate": (e['dueDate'] ?? '').toString(),
//             "createdAt": date,
//             "kind": (e['kind'] ?? '').toString(),
//           };
//         }).toList();

//         setState(() {
//           myAssigned = mapped;
//           isLoadingAssigned = false;
//         });
//       } else {
//         setState(() => isLoadingAssigned = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content:
//                     Text('Failed to fetch assigned tasks: ${resp.statusCode}')),
//           );
//         }
//       }
//     } catch (e) {
//       setState(() => isLoadingAssigned = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch assigned tasks: $e')),
//         );
//       }
//     }
//   }

//   // Dialog to show assigned tasks
//   void showAssignedTasksDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           " Assigned Tasks",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: isLoadingAssigned
//               ? const Center(child: CircularProgressIndicator())
//               : myAssigned.isEmpty
//                   ? const Text("No assigned tasks yet.")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: myAssigned.length,
//                       itemBuilder: (ctx, i) {
//                         final t = myAssigned[i];
//                         final hasDue =
//                             (t['dueDate'] as String).trim().isNotEmpty;
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             title: Text(t['title'] as String),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 if ((t['description'] as String).isNotEmpty)
//                                   Text(t['description'] as String),
//                                 Text("Assigned on: ${t['createdAt']}"),
//                                 if (hasDue) Text("Due: ${t['dueDate']}"),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close",
//                 style: TextStyle(color: Colors.deepPurple)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _pickDueDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _dueDate ?? now,
//       firstDate: DateTime(now.year - 1),
//       lastDate: DateTime(now.year + 5),
//     );
//     if (picked != null) {
//       setState(() => _dueDate = picked);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F6FF),
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
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//           ),
//         ),
//       ),
//       body: Container(
//         height: double.infinity,
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFF8F6FF), Color(0xFFE8E4FF)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Task Assignment Card
//               _buildSectionCard(
//                 title: "Task Assignment",
//                 child: Column(
//                   children: [
//                     Form(
//                       key: _formKey,
//                       child: Column(
//                         children: [
//                           _buildDropdownField(),
//                           const SizedBox(height: 16),
//                           if (_audience == 'employee') _buildEmployeeIdField(),
//                           if (_audience == 'employee') const SizedBox(height: 16),
//                           _buildTitleField(),
//                           const SizedBox(height: 16),
//                           _buildDescriptionField(),
//                           const SizedBox(height: 20),
//                           _buildActionRow(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Daily Updates Card
//               _buildSectionCard(
//                 title: "My Assigned Tasks",
//                 child: Column(
//                   children: [
//                     const Text(
//                       "View tasks assigned by admin",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF666666),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                    _buildViewButton(
//                     text: "View Daily Updates",
//                          onPressed: () async {
//                            await fetchDailyUpdates();
//                            if (!mounted) return;
//                            showDailyUpdateDialog();
//                          },
//                    ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Assigned Tasks Card
//               _buildSectionCard(
//                 title: "Daily Updates",
//                 child: Column(
//                   children: [
//                     const Text(
//                       "View user's daily work updates",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF666666),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildViewButton(
//                       text: "View Daily Updates",
//                       onPressed: () async {
//                         await fetchMyAssignedTasks();
//                         if (!mounted) return;
//                         showAssignedTasksDialog();
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Modern UI Helper Methods
//   Widget _buildSectionCard({required String title, required Widget child}) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF333333),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             child,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdownField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//       ),
//       child: DropdownButtonFormField<String>(
//         initialValue: _audience,
//         isExpanded: true,
//         items: const [
//           DropdownMenuItem(
//             value: 'all',
//             child: Text('All employees'),
//           ),
//           DropdownMenuItem(
//             value: 'employee',
//             child: Text('One employee'),
//           ),
//         ],
//         decoration: const InputDecoration(
//           labelText: 'Assign to',
//           labelStyle: TextStyle(color: Color(0xFF666666)),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         ),
//         onChanged: (v) {
//           if (v == null) return;
//           setState(() => _audience = v);
//         },
//       ),
//     );
//   }

//   Widget _buildEmployeeIdField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//       ),
//       child: TextFormField(
//         controller: _empIdCtrl,
//         decoration: const InputDecoration(
//           labelText: 'Employee ID',
//           labelStyle: TextStyle(color: Color(0xFF666666)),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           hintText: 'Enter employee ID',
//           hintStyle: TextStyle(color: Color(0xFF999999)),
//         ),
//         validator: (v) {
//           if (_audience == 'employee' && (v == null || v.trim().isEmpty)) {
//             return 'Employee ID is required for single assignment';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   Widget _buildTitleField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//       ),
//       child: TextFormField(
//         controller: _titleCtrl,
//         decoration: const InputDecoration(
//           labelText: 'Task Title',
//           labelStyle: TextStyle(color: Color(0xFF666666)),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           hintText: 'Enter task title',
//           hintStyle: TextStyle(color: Color(0xFF999999)),
//         ),
//         validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//       ),
//     );
//   }

//   Widget _buildDescriptionField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//       ),
//       child: TextFormField(
//         controller: _descCtrl,
//         maxLines: 4,
//         decoration: const InputDecoration(
//           labelText: 'Description',
//           labelStyle: TextStyle(color: Color(0xFF666666)),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           hintText: 'Describe the task details',
//           hintStyle: TextStyle(color: Color(0xFF999999)),
//         ),
//         validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//       ),
//     );
//   }

//   Widget _buildActionRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//             ),
//             child: InkWell(
//               onTap: _pickDueDate,
//               borderRadius: BorderRadius.circular(12),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.calendar_today, color: Color(0xFF8E71B7), size: 20),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         _dueDate == null ? 'Pick due date (optional)' : 'Due: ${_fmtDate(_dueDate!)}',
//                         style: TextStyle(
//                           color: _dueDate == null ? const Color(0xFF666666) : const Color(0xFF333333),
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Container(
//           height: 48,
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF8E71B7), Color(0xFF6B5E94)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF8E71B7).withValues(alpha: 0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ElevatedButton(
//             onPressed: _createBroadcastTask,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             ),
//             child: const Text(
//               "Submit",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildViewButton({required String text, required VoidCallback onPressed}) {
//     return Container(
//       width: double.infinity,
//       height: 48,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF8E71B7), Color(0xFF6B5E94)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF8E71B7).withValues(alpha: 0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Auth token you already use elsewhere (e.g., LiveAttendancePage)
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  // API base
  static final String _apiBase = ApiConfig.baseUrl;

  // Daily updates (from API)
  List<Map<String, dynamic>> dailyUpdates = [];
  bool isLoadingUpdates = false;

  // My assigned tasks
  List<Map<String, dynamic>> myAssigned = [];
  bool isLoadingAssigned = false;

  // Simple "broadcast task" form (TEXT ONLY now)
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  DateTime? _dueDate;

  // dropdown state -> 'all' or 'employee'
  String _audience = 'all';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _empIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();

    CompanyData.empid =
        prefs.getString('empid') ?? prefs.getString('empId') ?? '';

    CompanyData.companyId = prefs.getString('companyId') ?? '';

    await fetchMyAssignedTasks();
    await fetchDailyUpdates();
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// Fetch daily updates from /tasks/employee endpoint
  Future<void> fetchDailyUpdates() async {
    setState(() => isLoadingUpdates = true);
    try {
      final uri = Uri.parse(
          '${ApiService.baseUrl}/tasks/employee?limit=50&t=${DateTime.now().millisecondsSinceEpoch}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

      final token = CompanyData.token;

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);

        final daily = list.where((e) {
          final kind =
              (e['kind'] ?? '').toString().toLowerCase().replaceAll(' ', '');

          return kind == 'dailyupdate';
        }).toList();

        final mapped = daily.map((e) {
          return {
            "date": (e['createdAt'] ?? '').toString().split('T').first,
            "update": (e['description'] ?? '').toString(),
            "updatedBy": (e['assignedTo'] ?? e['createdBy'] ?? '').toString(),
          };
        }).toList();

        setState(() {
          dailyUpdates = mapped;
          isLoadingUpdates = false;
        });
      } else {
        setState(() => isLoadingUpdates = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to fetch updates: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoadingUpdates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch updates: $e')),
        );
      }
    }
  }

  /// Create a task:
  /// - If _audience == 'all': broadcast to everyone
  /// - If _audience == 'employee': assign only to given empid
  Future<void> _createBroadcastTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audience == 'employee' && _empIdCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter: employee empid.')),
        );
      }
      return;
    }

    final uri = Uri.parse('${ApiService.baseUrl}/tasks/broadcast');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = CompanyData.token;

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "dueDate": _dueDate == null ? null : _fmtDate(_dueDate!),
      "kind": "Task",
      "audience": _audience,
      if (_audience == 'employee') "assignedTo": _empIdCtrl.text.trim(),
    };

    try {
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _empIdCtrl.clear();

        setState(() => _dueDate = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void showDailyUpdateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "User Daily Updates",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoadingUpdates
              ? const Center(child: CircularProgressIndicator())
              : dailyUpdates.isEmpty
                  ? const Text("No user daily updates yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: dailyUpdates.length,
                      itemBuilder: (ctx, i) {
                        final u = dailyUpdates[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text("${u['date']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${u['update']}"),
                                if ((u['updatedBy'] as String).isNotEmpty)
                                  Text("${u['updatedBy']}"),
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
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch tasks assigned to this employee
  Future<void> fetchMyAssignedTasks() async {
    setState(() => isLoadingAssigned = true);

    try {
      final uri = Uri.parse(
          '${ApiService.baseUrl}/tasks/employee?limit=50&t=${DateTime.now().millisecondsSinceEpoch}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final token = CompanyData.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);

        final assigned = list.where((e) {
          final kind =
              (e['kind'] ?? '').toString().toLowerCase().replaceAll(' ', '');
          return kind == 'task';
        }).toList();

        final mapped = assigned.map<Map<String, dynamic>>((e) {
          final createdAt = (e['createdAt'] ?? '').toString();
          final date =
              createdAt.contains('T') ? createdAt.split('T').first : createdAt;
          final totalAssignments =
              e['totalAssignments'] is int ? e['totalAssignments'] as int : 0;
          final completedCount =
              e['completedCount'] is int ? e['completedCount'] as int : 0;
          final assignments = e['assignments'] is List
              ? List<Map<String, dynamic>>.from(e['assignments'] as List)
              : <Map<String, dynamic>>[];

          return {
            "id": (e['id'] ?? '').toString(),
            "title": (e['title'] ?? 'Task').toString(),
            "description": (e['description'] ?? '').toString(),
            "dueDate": (e['dueDate'] ?? '').toString(),
            "createdAt": date,
            "assignedTo": (e['assignedTo'] ?? 'All employees').toString(),
            "audience": (e['audience'] ?? 'all').toString(),
            "kind": (e['kind'] ?? '').toString(),
            "status": (e['status'] ?? 'assigned').toString(),
            "createdBy": (e['createdBy'] ?? '').toString(),
            "completedAt": (e['completedAt'] ?? '').toString(),
            "completionNote": (e['completionNote'] ?? '').toString(),
            "proofFileUrl": (e['proofFileUrl'] ?? '').toString(),
            "completedCount": completedCount,
            "totalAssignments": totalAssignments,
            "assignments": assignments,
          };
        }).toList();

        setState(() {
          myAssigned = mapped;
          isLoadingAssigned = false;
        });
      } else {
        setState(() => isLoadingAssigned = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to fetch assigned tasks: ${resp.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoadingAssigned = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch assigned tasks: $e')),
        );
      }
    }
  }

  void showAssignedTasksDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Company Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoadingAssigned
              ? const Center(child: CircularProgressIndicator())
              : myAssigned.isEmpty
                  ? const Text("No tasks found.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: myAssigned.length,
                      itemBuilder: (ctx, i) {
                        final t = myAssigned[i];
                        final hasDue =
                            (t['dueDate'] as String).trim().isNotEmpty;
                        final status = (t['status'] as String).toString();
                        final isCompleted = status.toLowerCase() == 'completed';

                        final completedCount = t['completedCount'] as int? ?? 0;
                        final totalAssignments =
                            t['totalAssignments'] as int? ?? 0;
                        final hasProgress = totalAssignments > 0;
                        final progressText = hasProgress
                            ? "$completedCount / $totalAssignments Completed"
                            : "Status: $status";

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(t['title'] as String),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((t['description'] as String).isNotEmpty)
                                  Text(t['description'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                Text("Assigned to: ${t['assignedTo']}"),
                                Text(progressText),
                                if (hasProgress)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 2),
                                    child: LinearProgressIndicator(
                                      value: totalAssignments == 0
                                          ? 0
                                          : completedCount / totalAssignments,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCompleted
                                            ? Colors.green
                                            : const Color(0xFF8C6EAF),
                                      ),
                                    ),
                                  ),
                                Text("Created: ${t['createdAt']}"),
                                if (hasDue) Text("Due: ${t['dueDate']}"),
                              ],
                            ),
                            trailing: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.assignment,
                              color: isCompleted ? Colors.green : Colors.orange,
                            ),
                            onTap: () => showTaskDetailDialog(t),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  void showTaskDetailDialog(Map<String, dynamic> task) {
    final status = (task['status'] as String).toString();
    final isCompleted = status.toLowerCase() == 'completed';
    final completedCount = task['completedCount'] as int? ?? 0;
    final totalAssignments = task['totalAssignments'] as int? ?? 0;
    final hasProgress = totalAssignments > 0;
    final assignments = task['assignments'] is List
        ? List<Map<String, dynamic>>.from(task['assignments'] as List)
        : <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Task Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("Title", task['title'] as String),
              _detailRow("Description", task['description'] as String),
              _detailRow("Assigned To", task['assignedTo'] as String),
              _detailRow("Status", status),
              _detailRow("Created By", task['createdBy'] as String),
              _detailRow("Created Date", task['createdAt'] as String),
              if ((task['dueDate'] as String).trim().isNotEmpty)
                _detailRow("Due Date", task['dueDate'] as String),
              if (hasProgress) ...[
                const Divider(),
                const Text(
                  "Progress",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _detailRow("Completed", "$completedCount / $totalAssignments"),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                    value: completedCount / totalAssignments,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : const Color(0xFF8C6EAF),
                    ),
                  ),
                ),
              ],
              if (assignments.isNotEmpty) ...[
                const Divider(),
                const Text(
                  "Employee Progress",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...assignments.map((a) =>
                    _buildAssignmentTile(context, task['id'] as String, a)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(
      BuildContext context, String taskId, Map<String, dynamic> a) {
    final employeeId = (a['employeeId'] ?? '').toString();
    final assignmentStatus =
        (a['status'] ?? 'assigned').toString().toLowerCase();
    final isCompleted = assignmentStatus == 'completed';
    final completedAt = (a['completedAt'] ?? '').toString();
    final completionNote = (a['completionNote'] ?? '').toString();
    final proofFileUrl = (a['proofFileUrl'] ?? '').toString();
    final hasProof = isCompleted && proofFileUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    employeeId,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? "Completed" : "Assigned",
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (isCompleted && completedAt.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Completed: ${_formatDate(completedAt)}",
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
            if (isCompleted && completionNote.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Note: $completionNote",
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
            if (hasProof) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _viewProof(taskId, employeeId),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("View Proof"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  Future<void> _viewProof(String taskId, String employeeId) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/tasks/$taskId/proof-url?empid=${Uri.encodeComponent(employeeId)}',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final token = CompanyData.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('[ADMIN PROOF] Fetching proof URL');
      final resp = await http.get(uri, headers: headers);
      debugPrint('[ADMIN PROOF] Response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final signedUrl = data['url'] as String;
        debugPrint('[ADMIN PROOF] Signed URL received');

        if (signedUrl.isNotEmpty) {
          final launched = await launchUrl(
            Uri.parse(signedUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open file')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to get proof URL')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load proof: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('[ADMIN PROOF] Error occurred');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading proof: $e')),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14),
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
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8C6EAF),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Tasks",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6FF), Color(0xFFE8E4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSectionCard(
                title: "Task Assignment",
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildDropdownField(),
                          const SizedBox(height: 16),
                          if (_audience == 'employee') _buildEmployeeIdField(),
                          if (_audience == 'employee')
                            const SizedBox(height: 16),
                          _buildTitleField(),
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 20),
                          _buildActionRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: "Task Management",
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: _buildViewButton(
                        text: "View Completed Tasks",
                        onPressed: () async {
                          await fetchMyAssignedTasks();
                          if (!mounted) return;
                          showAssignedTasksDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _audience,
        isExpanded: true,
        items: const [
          DropdownMenuItem(
            value: 'all',
            child: Text('All employees'),
          ),
          DropdownMenuItem(
            value: 'employee',
            child: Text('One employee'),
          ),
        ],
        decoration: const InputDecoration(
          labelText: 'Assign to',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _audience = v);
        },
      ),
    );
  }

  Widget _buildEmployeeIdField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _empIdCtrl,
        decoration: const InputDecoration(
          labelText: 'Employee ID',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Enter employee ID',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) {
          if (_audience == 'employee' && (v == null || v.trim().isEmpty)) {
            return 'Employee ID is required for single assignment';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Task Title',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Enter task title',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _descCtrl,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Describe the task details',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF8E71B7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Pick due date (optional)'
                            : 'Due: ${_fmtDate(_dueDate!)}',
                        style: TextStyle(
                          color: _dueDate == null
                              ? const Color(0xFF666666)
                              : const Color(0xFF333333),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E71B7), Color(0xFF6B5E94)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E71B7).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _createBroadcastTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E71B7), Color(0xFF6B5E94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E71B7).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
