
// // // // // // // import 'dart:io';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // // const Color kTextColor = Colors.white;

// // // // // // // class MyTaskPage extends StatefulWidget {
// // // // // // //   const MyTaskPage({super.key});

// // // // // // //   @override
// // // // // // //   State<MyTaskPage> createState() => _MyTaskPageState();
// // // // // // // }

// // // // // // // class _MyTaskPageState extends State<MyTaskPage> {
// // // // // // //   final Map<String, String?> uploadedFiles = {
// // // // // // //     'Task assigned': null,
// // // // // // //     'Daily Update': null,
// // // // // // //   };

// // // // // // //   final Map<String, bool> showPreview = {
// // // // // // //     'Task assigned': false,
// // // // // // //     'Daily Update': false,
// // // // // // //   };

// // // // // // //   Future<void> _pickFile(String section) async {
// // // // // // //     final result = await FilePicker.platform.pickFiles(allowMultiple: false);

// // // // // // //     if (result != null && result.files.single.path != null) {
// // // // // // //       final filePath = result.files.single.path!;
// // // // // // //       print("Picked File: $filePath");

// // // // // // //       setState(() {
// // // // // // //         uploadedFiles[section] = filePath;
// // // // // // //         showPreview[section] = false;
// // // // // // //       });

// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text('File uploaded for "$section"')),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _viewFile(String section) {
// // // // // // //     final filePath = uploadedFiles[section];

// // // // // // //     if (filePath == null) {
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text('No file uploaded for "$section"')),
// // // // // // //       );
// // // // // // //       return;
// // // // // // //     }

// // // // // // //     final extension = filePath.split('.').last.toLowerCase();
// // // // // // //     final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

// // // // // // //     if (isImage) {
// // // // // // //       final file = File(filePath);
// // // // // // //       if (file.existsSync()) {
// // // // // // //         setState(() {
// // // // // // //           showPreview[section] = true;
// // // // // // //         });
// // // // // // //       } else {
// // // // // // //         print("File does not exist at: $filePath");
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           const SnackBar(content: Text('Image file not found')),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     } else {
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         const SnackBar(content: Text('Only image preview supported')),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Scaffold(
// // // // // // //       backgroundColor: kPrimaryBackgroundTop,
// // // // // // //       body: Container(
// // // // // // //         decoration: const BoxDecoration(
// // // // // // //           gradient: LinearGradient(
// // // // // // //             begin: Alignment.topCenter,
// // // // // // //             end: Alignment.bottomCenter,
// // // // // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         child: SafeArea(
// // // // // // //           child: Padding(
// // // // // // //             padding: const EdgeInsets.all(20.0),
// // // // // // //             child: ListView(
// // // // // // //               children: [
// // // // // // //                 _buildHeader(context),
// // // // // // //                 const SizedBox(height: 20),
// // // // // // //                 const Center(
// // // // // // //                   child: Text(
// // // // // // //                     'My Tasks',
// // // // // // //                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 30),
// // // // // // //                 ...uploadedFiles.keys.map((section) => _buildTaskSection(section)).toList(),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _buildHeader(BuildContext context) {
// // // // // // //     return Row(
// // // // // // //       children: [
// // // // // // //         IconButton(
// // // // // // //           icon: const Icon(Icons.arrow_back, color: Colors.black),
// // // // // // //           onPressed: () => Navigator.pop(context),
// // // // // // //         ),
// // // // // // //         const SizedBox(width: 8),
// // // // // // //         const Text("Others", style: TextStyle(fontSize: 16)),
// // // // // // //         const Icon(Icons.arrow_right, color: kButtonColor),
// // // // // // //         const Text("My Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _buildTaskSection(String section) {
// // // // // // //     final filePath = uploadedFiles[section];
// // // // // // //     final shouldShowImage = showPreview[section] ?? false;
// // // // // // //     final isImage = filePath != null &&
// // // // // // //         filePath.contains('.') &&
// // // // // // //         ['jpg', 'jpeg', 'png', 'gif'].contains(filePath.split('.').last.toLowerCase());

// // // // // // //     return Column(
// // // // // // //       children: [
// // // // // // //         Container(
// // // // // // //           width: double.infinity,
// // // // // // //           margin: const EdgeInsets.symmetric(vertical: 10),
// // // // // // //           padding: const EdgeInsets.symmetric(vertical: 14),
// // // // // // //           decoration: BoxDecoration(
// // // // // // //             color: kAppBarColor,
// // // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // // //           ),
// // // // // // //           child: Center(
// // // // // // //             child: Text(
// // // // // // //               section,
// // // // // // //               style: const TextStyle(
// // // // // // //                 fontSize: 18,
// // // // // // //                 fontWeight: FontWeight.bold,
// // // // // // //                 color: kTextColor,
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         Row(
// // // // // // //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // // // //           children: [
// // // // // // //             if (section != 'Daily Update') // ✅ Upload hidden for Daily Update
// // // // // // //               _buildActionButton('Upload', () => _pickFile(section)),
// // // // // // //             _buildActionButton('View', () => _viewFile(section)),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 15),
// // // // // // //         if (filePath != null && shouldShowImage && isImage)
// // // // // // //           Padding(
// // // // // // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // // //             child: ClipRRect(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //               child: Image.file(
// // // // // // //                 File(filePath),
// // // // // // //                 height: 220,
// // // // // // //                 fit: BoxFit.contain,
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         const SizedBox(height: 20),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _buildActionButton(String label, VoidCallback onTap) {
// // // // // // //     return Card(
// // // // // // //       elevation: 4,
// // // // // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // // //       child: ElevatedButton(
// // // // // // //         onPressed: onTap,
// // // // // // //         style: ElevatedButton.styleFrom(
// // // // // // //           backgroundColor: kButtonColor,
// // // // // // //           foregroundColor: kTextColor,
// // // // // // //           padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
// // // // // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // // //         ),
// // // // // // //         child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }


// // // // // // import 'dart:io';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // const Color kTextColor = Colors.white;

// // // // // // class MyTaskPage extends StatefulWidget {
// // // // // //   const MyTaskPage({super.key});

// // // // // //   @override
// // // // // //   State<MyTaskPage> createState() => _MyTaskPageState();
// // // // // // }

// // // // // // class _MyTaskPageState extends State<MyTaskPage> {
// // // // // //   final Map<String, String?> uploadedFiles = {
// // // // // //     'Task assigned': null,
// // // // // //     'Daily Update': null,
// // // // // //   };

// // // // // //   final Map<String, bool> showPreview = {
// // // // // //     'Task assigned': false,
// // // // // //     'Daily Update': false,
// // // // // //   };

// // // // // //   Future<void> _pickFile(String section) async {
// // // // // //     final result = await FilePicker.platform.pickFiles(allowMultiple: false);

// // // // // //     if (result != null && result.files.single.path != null) {
// // // // // //       final filePath = result.files.single.path!;
// // // // // //       print("Picked File: $filePath");

// // // // // //       setState(() {
// // // // // //         uploadedFiles[section] = filePath;
// // // // // //         showPreview[section] = false;
// // // // // //       });

// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text('File uploaded for "$section"')),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   void _viewFile(String section) {
// // // // // //     final filePath = uploadedFiles[section];

// // // // // //     if (filePath == null) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text('No file uploaded for "$section"')),
// // // // // //       );
// // // // // //       return;
// // // // // //     }

// // // // // //     final extension = filePath.split('.').last.toLowerCase();
// // // // // //     final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

// // // // // //     if (isImage) {
// // // // // //       final file = File(filePath);
// // // // // //       if (file.existsSync()) {
// // // // // //         setState(() {
// // // // // //           showPreview[section] = true;
// // // // // //         });
// // // // // //       } else {
// // // // // //         print("File does not exist at: $filePath");
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(content: Text('Image file not found')),
// // // // // //         );
// // // // // //       }
// // // // // //     } else {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text('Only image preview supported')),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       backgroundColor: kPrimaryBackgroundTop,
// // // // // //       appBar: AppBar(
// // // // // //         backgroundColor: kAppBarColor,
// // // // // //         elevation: 0,
// // // // // //         leading: IconButton(
// // // // // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // // // // //           onPressed: () => Navigator.pop(context),
// // // // // //         ),
// // // // // //         title: const Text(
// // // // // //           'My Tasks',
// // // // // //           style: TextStyle(
// // // // // //             color: kTextColor,
// // // // // //             fontSize: 20,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //       body: Container(
// // // // // //         decoration: const BoxDecoration(
// // // // // //           gradient: LinearGradient(
// // // // // //             begin: Alignment.topCenter,
// // // // // //             end: Alignment.bottomCenter,
// // // // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // // // //           ),
// // // // // //         ),
// // // // // //         child: SafeArea(
// // // // // //           child: Padding(
// // // // // //             padding: const EdgeInsets.all(20.0),
// // // // // //             child: ListView(
// // // // // //               children: [
// // // // // //                 const SizedBox(height: 10),
// // // // // //                 ...uploadedFiles.keys.map((section) => _buildTaskSection(section)),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildTaskSection(String section) {
// // // // // //     final filePath = uploadedFiles[section];
// // // // // //     final shouldShowImage = showPreview[section] ?? false;
// // // // // //     final isImage = filePath != null &&
// // // // // //         filePath.contains('.') &&
// // // // // //         ['jpg', 'jpeg', 'png', 'gif'].contains(filePath.split('.').last.toLowerCase());

// // // // // //     return Column(
// // // // // //       children: [
// // // // // //         Container(
// // // // // //           width: double.infinity,
// // // // // //           margin: const EdgeInsets.symmetric(vertical: 10),
// // // // // //           padding: const EdgeInsets.symmetric(vertical: 14),
// // // // // //           decoration: BoxDecoration(
// // // // // //             color: kAppBarColor,
// // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // //           ),
// // // // // //           child: Center(
// // // // // //             child: Text(
// // // // // //               section,
// // // // // //               style: const TextStyle(
// // // // // //                 fontSize: 18,
// // // // // //                 fontWeight: FontWeight.bold,
// // // // // //                 color: kTextColor,
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //         Row(
// // // // // //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // // //           children: [
// // // // // //             if (section != 'Daily Update') // ✅ Upload hidden for Daily Update
// // // // // //               _buildActionButton('Upload', () => _pickFile(section)),
// // // // // //             _buildActionButton('View', () => _viewFile(section)),
// // // // // //           ],
// // // // // //         ),
// // // // // //         const SizedBox(height: 15),
// // // // // //         if (filePath != null && shouldShowImage && isImage)
// // // // // //           Padding(
// // // // // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // //             child: ClipRRect(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               child: Image.file(
// // // // // //                 File(filePath),
// // // // // //                 height: 220,
// // // // // //                 fit: BoxFit.contain,
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         const SizedBox(height: 20),
// // // // // //       ],
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildActionButton(String label, VoidCallback onTap) {
// // // // // //     return Card(
// // // // // //       elevation: 4,
// // // // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // //       child: ElevatedButton(
// // // // // //         onPressed: onTap,
// // // // // //         style: ElevatedButton.styleFrom(
// // // // // //           backgroundColor: kButtonColor,
// // // // // //           foregroundColor: kTextColor,
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
// // // // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // //         ),
// // // // // //         child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // import 'dart:io';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:file_picker/file_picker.dart';

// // // // // // ADDED: http + json + localStorage for API calls
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'dart:convert';
// // // // // // ignore: avoid_web_libraries_in_flutter
// // // // // import 'dart:html' as html;

// // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // const Color kTextColor = Colors.white;

// // // // // // ==== API base ====
// // // // // const String apiBase = 'http://localhost:3000';

// // // // // class MyTaskPage extends StatefulWidget {
// // // // //   const MyTaskPage({super.key});

// // // // //   @override
// // // // //   State<MyTaskPage> createState() => _MyTaskPageState();
// // // // // }

// // // // // class _MyTaskPageState extends State<MyTaskPage> {
// // // // //   final Map<String, String?> uploadedFiles = {
// // // // //     'Task assigned': null,
// // // // //     'Daily Update': null,
// // // // //   };

// // // // //   final Map<String, bool> showPreview = {
// // // // //     'Task assigned': false,
// // // // //     'Daily Update': false,
// // // // //   };

// // // // //   // ---------- AUTH HELPERS ----------
// // // // //   String? _readToken() {
// // // // //     final t1 = html.window.localStorage['token'];
// // // // //     if (t1 != null && t1.isNotEmpty) return t1;
// // // // //     final t2 = html.window.localStorage['jwt'];
// // // // //     if (t2 != null && t2.isNotEmpty) return t2;
// // // // //     final t3 = html.window.localStorage['authToken'];
// // // // //     if (t3 != null && t3.isNotEmpty) return t3;
// // // // //     return null;
// // // // //   }

// // // // //   Map<String, String> _authHeaders({bool json = true}) {
// // // // //     final token = _readToken();
// // // // //     final h = <String, String>{};
// // // // //     if (json) h['Content-Type'] = 'application/json';
// // // // //     if (token != null && token.isNotEmpty) {
// // // // //       h['Authorization'] = 'Bearer $token';
// // // // //       h['x-auth-token'] = token;
// // // // //     }
// // // // //     return h;
// // // // //   }

// // // // //   // ---------- MIME & DATA URL HELPERS ----------
// // // // //   String _mimeFromName(String name) {
// // // // //     final ext = name.split('.').last.toLowerCase();
// // // // //     switch (ext) {
// // // // //       case 'jpg':
// // // // //       case 'jpeg':
// // // // //         return 'image/jpeg';
// // // // //       case 'png':
// // // // //         return 'image/png';
// // // // //       case 'gif':
// // // // //         return 'image/gif';
// // // // //       case 'pdf':
// // // // //         return 'application/pdf';
// // // // //       case 'xlsx':
// // // // //         return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
// // // // //       case 'xls':
// // // // //         return 'application/vnd.ms-excel';
// // // // //       case 'csv':
// // // // //         return 'text/csv';
// // // // //       case 'doc':
// // // // //         return 'application/msword';
// // // // //       case 'docx':
// // // // //         return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
// // // // //       case 'txt':
// // // // //         return 'text/plain';
// // // // //       default:
// // // // //         return 'application/octet-stream';
// // // // //     }
// // // // //   }

// // // // //   Future<String?> _fileToDataUrl(PlatformFile file) async {
// // // // //     try {
// // // // //       List<int>? bytes = file.bytes;
// // // // //       if (bytes == null && file.path != null) {
// // // // //         bytes = await File(file.path!).readAsBytes();
// // // // //       }
// // // // //       if (bytes == null) return null;
// // // // //       final mime = _mimeFromName(file.name);
// // // // //       final b64 = base64Encode(bytes);
// // // // //       return 'data:$mime;base64,$b64';
// // // // //     } catch (_) {
// // // // //       return null;
// // // // //     }
// // // // //   }

// // // // //   // ---------- API: CREATE + UPDATE TASK (Task assigned only) ----------
// // // // //   Future<bool> _uploadTaskToApi(PlatformFile picked) async {
// // // // //     // 1) Create a task with title=file name, dueDate=now
// // // // //     final createRes = await http.post(
// // // // //       Uri.parse('$apiBase/api/tasks'),
// // // // //       headers: _authHeaders(),
// // // // //       body: jsonEncode({
// // // // //         'title': picked.name,
// // // // //         'description': 'Uploaded file',
// // // // //         'assignedTo': <String>[],                  // you can fill empids later if needed
// // // // //         'dueDate': DateTime.now().toIso8601String()
// // // // //       }),
// // // // //     );

// // // // //     if (createRes.statusCode != 201 && createRes.statusCode != 200) {
// // // // //       return false;
// // // // //     }

// // // // //     final created = jsonDecode(createRes.body) as Map<String, dynamic>;
// // // // //     final taskId = (created['id'] ?? created['taskId'] ?? '').toString();
// // // // //     if (taskId.isEmpty) return false;

// // // // //     // 2) Convert file to data URL and attach as uploadUrl
// // // // //     final dataUrl = await _fileToDataUrl(picked);
// // // // //     if (dataUrl == null) return false;

// // // // //     final updRes = await http.put(
// // // // //       Uri.parse('$apiBase/api/tasks/$taskId'),
// // // // //       headers: _authHeaders(),
// // // // //       body: jsonEncode({'uploadUrl': dataUrl}),
// // // // //     );

// // // // //     return updRes.statusCode == 200;
// // // // //   }

// // // // //   // ---------- API: LIST TASKS (Task assigned only; admin) ----------
// // // // //   Future<List<Map<String, dynamic>>> _fetchUploadedTasks() async {
// // // // //     final res = await http.get(Uri.parse('$apiBase/api/tasks'), headers: _authHeaders());
// // // // //     if (res.statusCode != 200) return <Map<String, dynamic>>[];
// // // // //     final arr = jsonDecode(res.body);
// // // // //     if (arr is! List) return <Map<String, dynamic>>[];
// // // // //     return arr
// // // // //         .where((e) => (e is Map && (e['uploadUrl'] ?? '').toString().isNotEmpty))
// // // // //         .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
// // // // //         .toList();
// // // // //   }

// // // // //   // ---------- EXISTING UI ACTIONS (kept) ----------
// // // // //   Future<void> _pickFile(String section) async {
// // // // //     final result = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);

// // // // //     if (result != null && result.files.single != null) {
// // // // //       final picked = result.files.single;

// // // // //       if (section == 'Task assigned') {
// // // // //         // Send to API
// // // // //         final ok = await _uploadTaskToApi(picked);
// // // // //         if (!mounted) return;

// // // // //         if (ok) {
// // // // //           setState(() {
// // // // //             uploadedFiles[section] = picked.path ?? picked.name; // keep local ref (for images if needed)
// // // // //             showPreview[section] = false;
// // // // //           });
// // // // //           ScaffoldMessenger.of(context).showSnackBar(
// // // // //             const SnackBar(content: Text('Task uploaded successfully')),
// // // // //           );
// // // // //         } else {
// // // // //           ScaffoldMessenger.of(context).showSnackBar(
// // // // //             const SnackBar(content: Text('Upload failed')),
// // // // //           );
// // // // //         }
// // // // //         return;
// // // // //       }

// // // // //       // Daily Update remains local-only (no API integration)
// // // // //       if (picked.path != null) {
// // // // //         setState(() {
// // // // //           uploadedFiles[section] = picked.path!;
// // // // //           showPreview[section] = false;
// // // // //         });
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(content: Text('File uploaded for "$section"')),
// // // // //         );
// // // // //       } else {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text('File not accessible on this platform')),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   void _viewFile(String section) async {
// // // // //     if (section == 'Task assigned') {
// // // // //       // Load from API and show list
// // // // //       final items = await _fetchUploadedTasks();
// // // // //       if (!mounted) return;

// // // // //       if (items.isEmpty) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text('No tasks found')),
// // // // //         );
// // // // //         return;
// // // // //       }

// // // // //       showModalBottomSheet(
// // // // //         context: context,
// // // // //         showDragHandle: true,
// // // // //         backgroundColor: Colors.white,
// // // // //         shape: const RoundedRectangleBorder(
// // // // //           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// // // // //         ),
// // // // //         builder: (_) {
// // // // //           return ListView.separated(
// // // // //             padding: const EdgeInsets.all(16),
// // // // //             itemCount: items.length,
// // // // //             separatorBuilder: (_, __) => const Divider(height: 1),
// // // // //             itemBuilder: (ctx, i) {
// // // // //               final t = items[i];
// // // // //               final name = (t['title'] ?? t['name'] ?? 'Task file').toString();
// // // // //               final created = (t['createdAt'] ?? '').toString();
// // // // //               final url = (t['uploadUrl'] ?? '').toString();

// // // // //               return ListTile(
// // // // //                 dense: true,
// // // // //                 leading: const Icon(Icons.insert_drive_file),
// // // // //                 title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
// // // // //                 subtitle:
// // // // //                     created.isEmpty ? null : Text(created, maxLines: 1, overflow: TextOverflow.ellipsis),
// // // // //                 trailing: IconButton(
// // // // //                   icon: const Icon(Icons.open_in_new),
// // // // //                   onPressed: url.isEmpty
// // // // //                       ? null
// // // // //                       : () {
// // // // //                           // Open in a new tab/window (works for data URLs too)
// // // // //                           html.window.open(url, '_blank');
// // // // //                         },
// // // // //                 ),
// // // // //               );
// // // // //             },
// // // // //           );
// // // // //         },
// // // // //       );
// // // // //       return;
// // // // //     }

// // // // //     // ---- Daily Update view (unchanged – local image-only preview) ----
// // // // //     final filePath = uploadedFiles[section];

// // // // //     if (filePath == null) {
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         SnackBar(content: Text('No file uploaded for "$section"')),
// // // // //       );
// // // // //       return;
// // // // //     }

// // // // //     final extension = filePath.split('.').last.toLowerCase();
// // // // //     final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

// // // // //     if (isImage) {
// // // // //       final file = File(filePath);
// // // // //       if (file.existsSync()) {
// // // // //         setState(() {
// // // // //           showPreview[section] = true;
// // // // //         });
// // // // //       } else {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text('Image file not found')),
// // // // //         );
// // // // //       }
// // // // //     } else {
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         const SnackBar(content: Text('Only image preview supported')),
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor: kPrimaryBackgroundTop,
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: kAppBarColor,
// // // // //         elevation: 0,
// // // // //         leading: IconButton(
// // // // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // // // //           onPressed: () => Navigator.pop(context),
// // // // //         ),
// // // // //         title: const Text(
// // // // //           'My Tasks',
// // // // //           style: TextStyle(
// // // // //             color: kTextColor,
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //       body: Container(
// // // // //         decoration: const BoxDecoration(
// // // // //           gradient: LinearGradient(
// // // // //             begin: Alignment.topCenter,
// // // // //             end: Alignment.bottomCenter,
// // // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // // //           ),
// // // // //         ),
// // // // //         child: SafeArea(
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.all(20.0),
// // // // //             child: ListView(
// // // // //               children: [
// // // // //                 const SizedBox(height: 10),
// // // // //                 ...uploadedFiles.keys.map((section) => _buildTaskSection(section)),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildTaskSection(String section) {
// // // // //     final filePath = uploadedFiles[section];
// // // // //     final shouldShowImage = showPreview[section] ?? false;
// // // // //     final isImage = filePath != null &&
// // // // //         filePath.contains('.') &&
// // // // //         ['jpg', 'jpeg', 'png', 'gif'].contains(filePath.split('.').last.toLowerCase());

// // // // //     return Column(
// // // // //       children: [
// // // // //         Container(
// // // // //           width: double.infinity,
// // // // //           margin: const EdgeInsets.symmetric(vertical: 10),
// // // // //           padding: const EdgeInsets.symmetric(vertical: 14),
// // // // //           decoration: BoxDecoration(
// // // // //             color: kAppBarColor,
// // // // //             borderRadius: BorderRadius.circular(16),
// // // // //           ),
// // // // //           child: Center(
// // // // //             child: Text(
// // // // //               section,
// // // // //               style: const TextStyle(
// // // // //                 fontSize: 18,
// // // // //                 fontWeight: FontWeight.bold,
// // // // //                 color: kTextColor,
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //         Row(
// // // // //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // //           children: [
// // // // //             if (section != 'Daily Update') // ✅ Upload hidden for Daily Update
// // // // //               _buildActionButton('Upload', () => _pickFile(section)),
// // // // //             _buildActionButton('View', () => _viewFile(section)),
// // // // //           ],
// // // // //         ),
// // // // //         const SizedBox(height: 15),
// // // // //         if (filePath != null && shouldShowImage && isImage)
// // // // //           Padding(
// // // // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // // // //             child: ClipRRect(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               child: Image.file(
// // // // //                 File(filePath),
// // // // //                 height: 220,
// // // // //                 fit: BoxFit.contain,
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         const SizedBox(height: 20),
// // // // //       ],
// // // // //     );
// // // // //   }

// // // // //   Widget _buildActionButton(String label, VoidCallback onTap) {
// // // // //     return Card(
// // // // //       elevation: 4,
// // // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // //       child: ElevatedButton(
// // // // //         onPressed: onTap,
// // // // //         style: ElevatedButton.styleFrom(
// // // // //           backgroundColor: kButtonColor,
// // // // //           foregroundColor: kTextColor,
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
// // // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // //         ),
// // // // //         child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // import 'dart:io'; // kept to avoid UI changes in your existing preview logic
// // // // import 'dart:typed_data';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:file_picker/file_picker.dart';

// // // // // Firebase client-only (no custom backend)
// // // // // ensure initialized in main.dart
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:firebase_storage/firebase_storage.dart';

// // // // // For opening links in a new tab on Web
// // // // // ignore: avoid_web_libraries_in_flutter
// // // // import 'dart:html' as html;

// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;

// // // // class MyTaskPage extends StatefulWidget {
// // // //   const MyTaskPage({super.key});

// // // //   @override
// // // //   State<MyTaskPage> createState() => _MyTaskPageState();
// // // // }

// // // // class _MyTaskPageState extends State<MyTaskPage> {
// // // //   final Map<String, String?> uploadedFiles = {
// // // //     'Task assigned': null,
// // // //     'Daily Update': null,
// // // //   };

// // // //   final Map<String, bool> showPreview = {
// // // //     'Task assigned': false,
// // // //     'Daily Update': false,
// // // //   };

// // // //   // Helper to get MIME type from file name
// // // //   String _mimeFromName(String name) {
// // // //     final ext = name.split('.').last.toLowerCase();
// // // //     switch (ext) {
// // // //       case 'jpg':
// // // //       case 'jpeg':
// // // //         return 'image/jpeg';
// // // //       case 'png':
// // // //         return 'image/png';
// // // //       case 'gif':
// // // //         return 'image/gif';
// // // //       case 'pdf':
// // // //         return 'application/pdf';
// // // //       case 'xlsx':
// // // //         return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
// // // //       case 'xls':
// // // //         return 'application/vnd.ms-excel';
// // // //       case 'csv':
// // // //         return 'text/csv';
// // // //       case 'doc':
// // // //         return 'application/msword';
// // // //       case 'docx':
// // // //         return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
// // // //       case 'txt':
// // // //         return 'text/plain';
// // // //       default:
// // // //         return 'application/octet-stream';
// // // //     }
// // // //   }

// // // //   // ---------------------------
// // // //   // LOCAL file pick (kept as-is)
// // // //   // ---------------------------
// // // //   Future<void> _pickFile(String section) async {
// // // //     final result = await FilePicker.platform.pickFiles(allowMultiple: false);
// // // //     if (result != null && result.files.single.path != null) {
// // // //       final filePath = result.files.single.path!;
// // // //       setState(() {
// // // //         uploadedFiles[section] = filePath;
// // // //         showPreview[section] = false;
// // // //       });
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('File uploaded for "$section"')),
// // // //       );
// // // //     }
// // // //   }

// // // //   // ---------------------------
// // // //   // LOCAL view (kept as-is)
// // // //   // ---------------------------
// // // //   void _viewFile(String section) {
// // // //     final filePath = uploadedFiles[section];
// // // //     if (filePath == null) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('No file uploaded for "$section"')),
// // // //       );
// // // //       return;
// // // //     }

// // // //     final extension = filePath.split('.').last.toLowerCase();
// // // //     final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

// // // //     if (isImage) {
// // // //       final file = File(filePath);
// // // //       if (file.existsSync()) {
// // // //         setState(() {
// // // //           showPreview[section] = true;
// // // //         });
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text('Image file not found')),
// // // //         );
// // // //       }
// // // //     } else {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('Only image preview supported')),
// // // //       );
// // // //     }
// // // //   }

// // // //   // ======================================================
// // // //   // NEW: Firebase client-only storage for "Task assigned"
// // // //   // ======================================================

// // // //   // Uploads picked file to Firebase Storage and writes Firestore "tasks" doc.
// // // //   Future<void> _uploadTaskAssignedFirebase() async {
// // // //     try {
// // // //       final picked = await FilePicker.platform.pickFiles(
// // // //         allowMultiple: false,
// // // //         withData: true, // important on Web
// // // //       );
// // // //       if (picked == null || picked.files.isEmpty) return;

// // // //       final f = picked.files.single;
// // // //       final Uint8List? bytes = f.bytes;
// // // //       final String name = f.name;
// // // //       final String contentType = _mimeFromName(f.name);

// // // //       if (bytes == null) {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text('Could not read file bytes')),
// // // //         );
// // // //         return;
// // // //       }

// // // //       // 1) Upload to Firebase Storage
// // // //       final id = DateTime.now().millisecondsSinceEpoch.toString();
// // // //       final storagePath = 'tasks/$id/$name';
// // // //       final ref = FirebaseStorage.instance.ref(storagePath);

// // // //       await ref.putData(
// // // //         bytes,
// // // //         SettableMetadata(
// // // //           contentType: contentType,
// // // //           cacheControl: 'public,max-age=31536000',
// // // //         ),
// // // //       );
// // // //       final downloadUrl = await ref.getDownloadURL();

// // // //       // 2) Create Firestore document
// // // //       final doc = {
// // // //         'id': id,
// // // //         'title': 'Task assigned',
// // // //         'description': 'Attachment uploaded',
// // // //         'fileName': name,
// // // //         'contentType': contentType,
// // // //         'uploadUrl': downloadUrl,
// // // //         'createdAt': FieldValue.serverTimestamp(),
// // // //         // add optional fields here if you later need them
// // // //       };
// // // //       await FirebaseFirestore.instance.collection('tasks').doc(id).set(doc);

// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('Uploaded successfully')),
// // // //       );
// // // //     } catch (e) {
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('Upload failed: $e')),
// // // //       );
// // // //     }
// // // //   }

// // // //   // Lists uploaded “Task assigned” docs and lets admin open the file in new tab.
// // // //   Future<void> _viewTaskAssignedFirebase() async {
// // // //     try {
// // // //       final snap = await FirebaseFirestore.instance
// // // //           .collection('tasks')
// // // //           .orderBy('createdAt', descending: true)
// // // //           .limit(30)
// // // //           .get();

// // // //       final items = snap.docs
// // // //           .map((d) => d.data())
// // // //           .where((m) => (m['uploadUrl'] ?? '').toString().isNotEmpty)
// // // //           .toList();

// // // //       if (items.isEmpty) {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text('No uploaded tasks yet')),
// // // //         );
// // // //         return;
// // // //       }

// // // //       if (!mounted) return;
// // // //       await showDialog(
// // // //         context: context,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text('Uploaded tasks'),
// // // //           content: SizedBox(
// // // //             width: 380,
// // // //             height: 420,
// // // //             child: ListView.builder(
// // // //               itemCount: items.length,
// // // //               itemBuilder: (_, i) {
// // // //                 final m = items[i];
// // // //                 final fileName = (m['fileName'] ?? 'file').toString();
// // // //                 final url = (m['uploadUrl'] ?? '').toString();
// // // //                 final createdAt = (m['createdAt'] != null)
// // // //                     ? (m['createdAt'] as Timestamp).toDate().toString()
// // // //                     : '';
// // // //                 return ListTile(
// // // //                   dense: true,
// // // //                   title: Text(fileName, overflow: TextOverflow.ellipsis),
// // // //                   subtitle: Text(createdAt, maxLines: 1, overflow: TextOverflow.ellipsis),
// // // //                   onTap: () => html.window.open(url, '_blank'),
// // // //                 );
// // // //               },
// // // //             ),
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context),
// // // //               child: const Text('Close'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //     } catch (e) {
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('Load failed: $e')),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: kPrimaryBackgroundTop,
// // // //       appBar: AppBar(
// // // //         backgroundColor: kAppBarColor,
// // // //         elevation: 0,
// // // //         leading: IconButton(
// // // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // // //           onPressed: () => Navigator.pop(context),
// // // //         ),
// // // //         title: const Text(
// // // //           'My Tasks',
// // // //           style: TextStyle(
// // // //             color: kTextColor,
// // // //             fontSize: 20,
// // // //             fontWeight: FontWeight.bold,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //       body: Container(
// // // //         decoration: const BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             begin: Alignment.topCenter,
// // // //             end: Alignment.bottomCenter,
// // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // //           ),
// // // //         ),
// // // //         child: SafeArea(
// // // //           child: Padding(
// // // //             padding: const EdgeInsets.all(20.0),
// // // //             child: ListView(
// // // //               children: [
// // // //                 const SizedBox(height: 10),
// // // //                 ...uploadedFiles.keys.map((section) => _buildTaskSection(section)),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildTaskSection(String section) {
// // // //     final filePath = uploadedFiles[section];
// // // //     final shouldShowImage = showPreview[section] ?? false;
// // // //     final isImage = filePath != null &&
// // // //         filePath.contains('.') &&
// // // //         ['jpg', 'jpeg', 'png', 'gif'].contains(filePath.split('.').last.toLowerCase());

// // // //     return Column(
// // // //       children: [
// // // //         Container(
// // // //           width: double.infinity,
// // // //           margin: const EdgeInsets.symmetric(vertical: 10),
// // // //           padding: const EdgeInsets.symmetric(vertical: 14),
// // // //           decoration: BoxDecoration(
// // // //             color: kAppBarColor,
// // // //             borderRadius: BorderRadius.circular(16),
// // // //           ),
// // // //           child: Center(
// // // //             child: Text(
// // // //               section,
// // // //               style: const TextStyle(
// // // //                 fontSize: 18,
// // // //                 fontWeight: FontWeight.bold,
// // // //                 color: kTextColor,
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         Row(
// // // //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // //           children: [
// // // //             // IMPORTANT: do NOT change UI; just switch handlers for "Task assigned"
// // // //             if (section != 'Daily Update')
// // // //               _buildActionButton(
// // // //                 'Upload',
// // // //                 section == 'Task assigned'
// // // //                     ? _uploadTaskAssignedFirebase // Firebase client-only
// // // //                     : () => _pickFile(section),   // unchanged fallback
// // // //               ),
// // // //             _buildActionButton(
// // // //               'View',
// // // //               section == 'Task assigned'
// // // //                   ? _viewTaskAssignedFirebase // Firebase client-only
// // // //                   : () => _viewFile(section),   // unchanged for "Daily Update"
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         const SizedBox(height: 15),
// // // //         if (filePath != null && shouldShowImage && isImage)
// // // //           Padding(
// // // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // // //             child: ClipRRect(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               child: Image.file(
// // // //                 File(filePath),
// // // //                 height: 220,
// // // //                 fit: BoxFit.contain,
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         const SizedBox(height: 20),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildActionButton(String label, VoidCallback onTap) {
// // // //     return Card(
// // // //       elevation: 4,
// // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //       child: ElevatedButton(
// // // //         onPressed: onTap,
// // // //         style: ElevatedButton.styleFrom(
// // // //           backgroundColor: kButtonColor,
// // // //           foregroundColor: kTextColor,
// // // //           padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
// // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //         ),
// // // //         child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // // lib/pages/my_task_page.dart
// // // import 'dart:typed_data';
// // // import 'package:flutter/foundation.dart' show kIsWeb;
// // // import 'package:flutter/material.dart';
// // // import 'package:file_picker/file_picker.dart';

// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_storage/firebase_storage.dart';

// // // // Web: open in new tab; Mobile/Desktop: fall back to url_launcher
// // // // ignore: avoid_web_libraries_in_flutter
// // // import 'dart:html' as html;
// // // import 'package:url_launcher/url_launcher.dart';

// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // class MyTaskPage extends StatefulWidget {
// // //   const MyTaskPage({super.key});

// // //   @override
// // //   State<MyTaskPage> createState() => _MyTaskPageState();
// // // }

// // // class _MyTaskPageState extends State<MyTaskPage> {
// // //   final Map<String, String?> uploadedFiles = {
// // //     'Task assigned': null,
// // //     'Daily Update': null,
// // //   };

// // //   final Map<String, bool> showPreview = {
// // //     'Task assigned': false,
// // //     'Daily Update': false,
// // //   };

// // //   String _mimeFromName(String name) {
// // //     final ext = name.split('.').last.toLowerCase();
// // //     switch (ext) {
// // //       case 'jpg':
// // //       case 'jpeg':
// // //         return 'image/jpeg';
// // //       case 'png':
// // //         return 'image/png';
// // //       case 'gif':
// // //         return 'image/gif';
// // //       case 'pdf':
// // //         return 'application/pdf';
// // //       case 'xlsx':
// // //         return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
// // //       case 'xls':
// // //         return 'application/vnd.ms-excel';
// // //       case 'csv':
// // //         return 'text/csv';
// // //       case 'doc':
// // //         return 'application/msword';
// // //       case 'docx':
// // //         return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
// // //       case 'txt':
// // //         return 'text/plain';
// // //       default:
// // //         return 'application/octet-stream';
// // //     }
// // //   }

// // //   // ---------------------------
// // //   // LOCAL file pick (kept for Daily Update ONLY; no preview on web)
// // //   // ---------------------------
// // //   Future<void> _pickFile(String section) async {
// // //     final result = await FilePicker.platform.pickFiles(allowMultiple: false);
// // //     if (result != null) {
// // //       final path = result.files.single.path; // may be null on web
// // //       setState(() {
// // //         uploadedFiles[section] = path; // used only for local preview
// // //         showPreview[section] = false;
// // //       });
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('File selected for "$section"')),
// // //       );
// // //     }
// // //   }

// // //   // ---------------------------
// // //   // LOCAL view (kept minimal & safe)
// // //   // ---------------------------
// // //   void _viewFile(String section) {
// // //     final filePath = uploadedFiles[section];
// // //     if (filePath == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('No file selected for "$section"')),
// // //       );
// // //       return;
// // //     }

// // //     // On web we can’t preview with Image.file; show a note.
// // //     if (kIsWeb) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Local image preview is not supported on Web.')),
// // //       );
// // //       return;
// // //     }

// // //     // On mobile/desktop we only toggle preview flag; actual preview UI is below.
// // //     final ext = filePath.split('.').last.toLowerCase();
// // //     final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
// // //     if (isImage) {
// // //       setState(() => showPreview[section] = true);
// // //     } else {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Only image preview is supported here.')),
// // //       );
// // //     }
// // //   }

// // //   // ======================================================
// // //   // Firebase client-only storage for "Task assigned"
// // //   // ======================================================
// // //   Future<void> _uploadTaskAssignedFirebase() async {
// // //     try {
// // //       final picked = await FilePicker.platform.pickFiles(
// // //         allowMultiple: false,
// // //         withData: true, // IMPORTANT for Web
// // //         type: FileType.any,
// // //       );
// // //       if (picked == null || picked.files.isEmpty) return;

// // //       final f = picked.files.single;
// // //       final Uint8List? bytes = f.bytes; // non-null on web when withData:true
// // //       final String name = f.name;
// // //       final String contentType = _mimeFromName(name);

// // //       if (bytes == null) {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('Could not read file bytes')),
// // //         );
// // //         return;
// // //       }

// // //       // 1) Upload to Firebase Storage
// // //       final id = DateTime.now().millisecondsSinceEpoch.toString();
// // //       final storagePath = 'tasks/$id/$name';
// // //       final ref = FirebaseStorage.instance.ref(storagePath);

// // //       await ref.putData(
// // //         bytes,
// // //         SettableMetadata(
// // //           contentType: contentType,
// // //           cacheControl: 'public,max-age=31536000',
// // //           customMetadata: {
// // //             'originalName': name,
// // //             'uploadedAt': DateTime.now().toIso8601String(),
// // //             'type': 'assigned',
// // //           },
// // //         ),
// // //       );
// // //       final downloadUrl = await ref.getDownloadURL();

// // //       // 2) Create Firestore document
// // //       await FirebaseFirestore.instance.collection('tasks').doc(id).set({
// // //         'id': id,
// // //         'title': 'Task assigned',
// // //         'description': 'Attachment uploaded',
// // //         'fileName': name,
// // //         'contentType': contentType,
// // //         'uploadUrl': downloadUrl,
// // //         'storagePath': storagePath,
// // //         'createdAt': FieldValue.serverTimestamp(),
// // //       });

// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Uploaded successfully')),
// // //       );
// // //     } on FirebaseException catch (e) {
// // //       if (!mounted) return;
// // //       // Keep this as a plain string — don’t forward to JS.
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Firebase error: ${e.code} — ${e.message}')),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Upload failed: $e')),
// // //       );
// // //     }
// // //   }

// // //   Future<void> _viewTaskAssignedFirebase() async {
// // //     try {
// // //       final snap = await FirebaseFirestore.instance
// // //           .collection('tasks')
// // //           .orderBy('createdAt', descending: true)
// // //           .limit(30)
// // //           .get();

// // //       final items = snap.docs
// // //           .map((d) => d.data())
// // //           .where((m) => (m['uploadUrl'] ?? '').toString().isNotEmpty)
// // //           .toList();

// // //       if (items.isEmpty) {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('No uploaded tasks yet')),
// // //         );
// // //         return;
// // //       }

// // //       if (!mounted) return;
// // //       await showDialog(
// // //         context: context,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text('Uploaded tasks'),
// // //           content: SizedBox(
// // //             width: 380,
// // //             height: 420,
// // //             child: ListView.builder(
// // //               itemCount: items.length,
// // //               itemBuilder: (_, i) {
// // //                 final m = items[i];
// // //                 final fileName = (m['fileName'] ?? 'file').toString();
// // //                 final url = (m['uploadUrl'] ?? '').toString();
// // //                 final createdAt = (m['createdAt'] != null)
// // //                     ? (m['createdAt'] as Timestamp).toDate().toString()
// // //                     : '';
// // //                 return ListTile(
// // //                   dense: true,
// // //                   title: Text(fileName, overflow: TextOverflow.ellipsis),
// // //                   subtitle: Text(createdAt, maxLines: 1, overflow: TextOverflow.ellipsis),
// // //                   onTap: () async {
// // //                     if (kIsWeb) {
// // //                       html.window.open(url, '_blank');
// // //                     } else {
// // //                       final uri = Uri.parse(url);
// // //                       await launchUrl(uri, mode: LaunchMode.externalApplication);
// // //                     }
// // //                   },
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context),
// // //               child: const Text('Close'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Load failed: $e')),
// // //       );
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: kPrimaryBackgroundTop,
// // //       appBar: AppBar(
// // //         backgroundColor: kAppBarColor,
// // //         elevation: 0,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //         title: const Text(
// // //           'My Tasks',
// // //           style: TextStyle(
// // //             color: kTextColor,
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //           ),
// // //         ),
// // //       ),
// // //       body: Container(
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //           ),
// // //         ),
// // //         child: SafeArea(
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(20.0),
// // //             child: ListView(
// // //               children: [
// // //                 const SizedBox(height: 10),
// // //                 ...uploadedFiles.keys.map((section) => _buildTaskSection(section)),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildTaskSection(String section) {
// // //     final filePath = uploadedFiles[section];
// // //     final shouldShowImage = showPreview[section] ?? false;

// // //     final isImage = (filePath != null &&
// // //         filePath.contains('.') &&
// // //         ['jpg', 'jpeg', 'png', 'gif']
// // //             .contains(filePath.split('.').last.toLowerCase()));

// // //     return Column(
// // //       children: [
// // //         Container(
// // //           width: double.infinity,
// // //           margin: const EdgeInsets.symmetric(vertical: 10),
// // //           padding: const EdgeInsets.symmetric(vertical: 14),
// // //           decoration: BoxDecoration(
// // //             color: kAppBarColor,
// // //             borderRadius: BorderRadius.circular(16),
// // //           ),
// // //           child: Center(
// // //             child: Text(
// // //               section,
// // //               style: const TextStyle(
// // //                 fontSize: 18,
// // //                 fontWeight: FontWeight.bold,
// // //                 color: kTextColor,
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //         Row(
// // //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //           children: [
// // //             if (section != 'Daily Update')
// // //               _buildActionButton(
// // //                 'Upload',
// // //                 section == 'Task assigned'
// // //                     ? _uploadTaskAssignedFirebase
// // //                     : () => _pickFile(section),
// // //               ),
// // //             _buildActionButton(
// // //               'View',
// // //               section == 'Task assigned'
// // //                   ? _viewTaskAssignedFirebase
// // //                   : () => _viewFile(section),
// // //             ),
// // //           ],
// // //         ),
// // //         const SizedBox(height: 15),

// // //         // Local image preview: only on non-web
// // //         if (!kIsWeb && filePath != null && shouldShowImage && isImage)
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // //             child: ClipRRect(
// // //               borderRadius: BorderRadius.circular(12),
// // //               child: Image.asset(
// // //                 filePath, // this is just a placeholder; File preview was removed for web safety
// // //                 height: 220,
// // //                 fit: BoxFit.contain,
// // //               ),
// // //             ),
// // //           ),
// // //         const SizedBox(height: 20),
// // //       ],
// // //     );
// // //   }

// // //   Widget _buildActionButton(String label, VoidCallback onTap) {
// // //     return Card(
// // //       elevation: 4,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: ElevatedButton(
// // //         onPressed: onTap,
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: kButtonColor,
// // //           foregroundColor: kTextColor,
// // //           padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
// // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //         ),
// // //         child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'package:file_picker/file_picker.dart';
// // import 'package:open_filex/open_filex.dart';
// // import 'dart:html' as html; // For Web file opening
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';

// // class MyTasksPage extends StatefulWidget {
// //   const MyTasksPage({super.key});

// //   @override
// //   State<MyTasksPage> createState() => _MyTasksPageState();
// // }

// // class _MyTasksPageState extends State<MyTasksPage> {
// //   List<PlatformFile> uploadedFiles = [];
// //   List<Map<String, dynamic>> dailyUpdates = [];
// //   bool isLoadingUpdates = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchDailyUpdates();
// //   }

// //   /// Fetch Daily Updates (dummy data for now)
// //   Future<void> fetchDailyUpdates() async {
// //     setState(() {
// //       isLoadingUpdates = true;
// //     });

// //     await Future.delayed(const Duration(seconds: 1)); // simulate loading

// //     // 🔹 Dummy Data
// //     setState(() {
// //       dailyUpdates = [
// //         {
// //           "date": "2025-08-14",
// //           "update": "Completed login screen UI",
// //           "timeSpent": "3 hours",
// //           "updatedBy": "John Doe",
// //           "file": "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
// //         },
// //         {
// //           "date": "2025-08-13",
// //           "update": "Fixed API integration bugs",
// //           "timeSpent": "2 hours",
// //           "updatedBy": "Jane Smith",
// //           "file": "https://file-examples.com/storage/fefc64b6b9b9/example.pdf"
// //         }
// //       ];
// //       isLoadingUpdates = false;
// //     });

// //     // If you want real API later, uncomment:
// //     /*
// //     try {
// //       final response = await http.get(Uri.parse("http://localhost:3000/daily-updates"));
// //       if (response.statusCode == 200) {
// //         final List<dynamic> data = jsonDecode(response.body);
// //         setState(() {
// //           dailyUpdates = data.map((e) => Map<String, dynamic>.from(e)).toList();
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint("Error fetching daily updates: $e");
// //     }
// //     setState(() => isLoadingUpdates = false);
// //     */
// //   }

// //   /// Pick file for "Task assigned"
// //   Future<void> pickFile() async {
// //     final result = await FilePicker.platform.pickFiles();
// //     if (result != null) {
// //       PlatformFile pickedFile = result.files.single;
// //       setState(() {
// //         uploadedFiles.add(pickedFile);
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text("✅ File uploaded successfully!"),
// //           backgroundColor: Colors.green,
// //         ),
// //       );
// //     }
// //   }

// //   /// Show uploaded files dialog
// //   void showUploadedFiles(List<PlatformFile> files, String title) {
// //     showDialog(
// //       context: context,
// //       builder: (_) => TaskUploadsDialog(files: files, title: title),
// //     );
// //   }

// //   /// Show Daily Updates dialog
// //   void showDailyUpdateDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         title: const Text("Daily Updates", style: TextStyle(fontWeight: FontWeight.bold)),
// //         content: SizedBox(
// //           width: double.maxFinite,
// //           child: isLoadingUpdates
// //               ? const Center(child: CircularProgressIndicator())
// //               : dailyUpdates.isEmpty
// //                   ? const Text("No daily updates yet.")
// //                   : ListView.builder(
// //                       shrinkWrap: true,
// //                       itemCount: dailyUpdates.length,
// //                       itemBuilder: (ctx, index) {
// //                         var update = dailyUpdates[index];
// //                         return Card(
// //                           margin: const EdgeInsets.symmetric(vertical: 6),
// //                           child: ListTile(
// //                             title: Text("📅 ${update['date']}"),
// //                             subtitle: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text("📝 ${update['update']}"),
// //                                 Text("⏱ ${update['timeSpent']}"),
// //                                 Text("👩‍💻 ${update['updatedBy']}"),
// //                               ],
// //                             ),
// //                             trailing: IconButton(
// //                               icon: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
// //                               onPressed: () {
// //                                 if (update['file'] != null) {
// //                                   _openFileFromURL(update['file']);
// //                                 }
// //                               },
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   /// Open file from URL
// //   void _openFileFromURL(String fileUrl) {
// //     if (kIsWeb) {
// //       html.window.open(fileUrl, "_blank");
// //     } else {
// //       OpenFilex.open(fileUrl);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF8E71B7),
// //         centerTitle: true,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.white),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text(
// //           "My Tasks",
// //           style: TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 20,
// //           ),
// //         ),
// //       ),
// //       body: Container(
// //         height: double.infinity,
// //         width: double.infinity,
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Colors.white, Color(0xFFD1C4E9)],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
// //         child: SingleChildScrollView(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               taskSection(
// //                 "Task assigned",
// //                 showUpload: true,
// //                 onUpload: () => pickFile(),
// //                 onView: () => showUploadedFiles(uploadedFiles, "Task Uploads"),
// //               ),
// //               const SizedBox(height: 30),
// //               taskSection(
// //                 "Daily Update",
// //                 showUpload: false,
// //                 onUpload: () {},
// //                 onView: showDailyUpdateDialog,
// //               ),
// //               const SizedBox(height: 30),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   /// Reusable Section
// //   Widget taskSection(
// //     String title, {
// //     required bool showUpload,
// //     required VoidCallback onUpload,
// //     required VoidCallback onView,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.center,
// //       children: [
// //         Center(
// //           child: Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF8E71B7),
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //             child: Text(
// //               title,
// //               style: const TextStyle(
// //                 fontSize: 18,
// //                 color: Colors.white,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 20),
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             if (showUpload)
// //               ElevatedButton(
// //                 onPressed: onUpload,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF6B5E94),
// //                   elevation: 4,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(20),
// //                   ),
// //                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                 ),
// //                 child: const Text("Upload", style: TextStyle(color: Colors.white)),
// //               ),
// //             if (showUpload) const SizedBox(width: 20),
// //             ElevatedButton(
// //               onPressed: onView,
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF6B5E94),
// //                 elevation: 4,
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //               ),
// //               child: const Text("View", style: TextStyle(color: Colors.white)),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// // }

// // /// Dialog for Uploaded Task Files
// // class TaskUploadsDialog extends StatelessWidget {
// //   final List<PlatformFile> files;
// //   final String title;

// //   const TaskUploadsDialog({
// //     Key? key,
// //     required this.files,
// //     required this.title,
// //   }) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return AlertDialog(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //       title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
// //       content: SizedBox(
// //         width: double.maxFinite,
// //         child: files.isEmpty
// //             ? const Center(child: Text("No files uploaded"))
// //             : ListView.builder(
// //                 shrinkWrap: true,
// //                 itemCount: files.length,
// //                 itemBuilder: (context, index) {
// //                   return ListTile(
// //                     leading: const Icon(Icons.insert_drive_file, size: 30),
// //                     title: Text(files[index].name),
// //                     onTap: () async {
// //                       Navigator.pop(context);
// //                       if (kIsWeb) {
// //                         final fileBytes = files[index].bytes;
// //                         final fileName = files[index].name;
// //                         if (fileBytes != null) {
// //                           final blob = html.Blob([fileBytes]);
// //                           final url = html.Url.createObjectUrlFromBlob(blob);
// //                           final anchor = html.AnchorElement(href: url)
// //                             ..target = '_blank'
// //                             ..download = fileName;
// //                           anchor.click();
// //                           html.Url.revokeObjectUrl(url);
// //                         }
// //                       } else {
// //                         if (files[index].path != null) {
// //                           await OpenFilex.open(files[index].path!);
// //                         }
// //                       }
// //                     },
// //                   );
// //                 },
// //               ),
// //       ),
// //       actions: [
// //         TextButton(
// //           onPressed: () => Navigator.pop(context),
// //           child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
// //         )
// //       ],
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:file_picker/file_picker.dart';
// import 'package:open_filex/open_filex.dart';
// import 'dart:html' as html; // Web open
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
//   static const String _apiBase = 'http://localhost:3000';

//   // local preview list (unchanged UI)
//   List<PlatformFile> uploadedFiles = [];

//   // dummy daily updates (unchanged)
//   List<Map<String, dynamic>> dailyUpdates = [];
//   bool isLoadingUpdates = false;

//   bool _isUploading = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchDailyUpdates();
//   }

//   Future<void> fetchDailyUpdates() async {
//     setState(() => isLoadingUpdates = true);
//     await Future.delayed(const Duration(seconds: 1));
//     setState(() {
//       dailyUpdates = [
//         {
//           "date": "2025-08-14",
//           "update": "Completed login screen UI",
//           "timeSpent": "3 hours",
//           "updatedBy": "John Doe",
//           "file": "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
//         },
//         {
//           "date": "2025-08-13",
//           "update": "Fixed API integration bugs",
//           "timeSpent": "2 hours",
//           "updatedBy": "Jane Smith",
//           "file": "https://file-examples.com/storage/fefc64b6b9b9/example.pdf"
//         }
//       ];
//       isLoadingUpdates = false;
//     });
//   }

//   /// Pick file for "Task assigned" and upload to backend (no UI changes)
//   Future<void> pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       withData: kIsWeb, // web needs bytes
//     );
//     if (result == null) return;

//     final PlatformFile picked = result.files.single;

//     // 1) Upload to backend → Firestore
//     final ok = await _uploadTaskToServer(picked);

//     // 2) Keep same UI behavior (show in the dialog) if upload succeeded
//     if (ok) {
//       setState(() => uploadedFiles.add(picked));
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ Uploaded to server (stored in Firestore).'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     }
//   }

//   /// POST /api/tasks/broadcast  (multipart: field name "file")
//   Future<bool> _uploadTaskToServer(PlatformFile file) async {
//     try {
//       setState(() => _isUploading = true);

//       final uri = Uri.parse('$_apiBase/api/tasks/broadcast');
//       final req = http.MultipartRequest('POST', uri);

//       // Authorization header if you use JWT
//       final token = CompanyData.token; // adjust if your token lives elsewhere
//       if (token != null && token.isNotEmpty) {
//         req.headers['Authorization'] = 'Bearer $token';
//       }

//       // Optional fields (server uses name as title if empty)
//       req.fields['title'] = file.name;
//       req.fields['description'] = 'Uploaded file';
//       req.fields['kind'] = 'Task';

//       // Attach file
//       if (kIsWeb) {
//         // bytes are required on web
//         if (file.bytes == null) {
//           throw Exception('No bytes for selected file on web');
//         }
//         req.files.add(
//           http.MultipartFile.fromBytes(
//             'file',
//             file.bytes!,
//             filename: file.name,
//           ),
//         );
//       } else {
//         // mobile/desktop: path is available
//         if (file.path == null) {
//           throw Exception('File path is null');
//         }
//         req.files.add(await http.MultipartFile.fromPath('file', file.path!));
//       }

//       final resp = await req.send();
//       final body = await resp.stream.bytesToString();

//       if (resp.statusCode == 201) {
//         // created in Firestore
//         // you can parse `body` if you want the created task back
//         return true;
//       } else {
//         debugPrint('Upload failed [${resp.statusCode}]: $body');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Upload failed: ${resp.statusCode}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Upload error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Upload error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return false;
//     } finally {
//       if (mounted) setState(() => _isUploading = false);
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
//                                 Text("⏱ ${update['timeSpent']}"),
//                                 Text("👩‍💻 ${update['updatedBy']}"),
//                               ],
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
//                               onPressed: () {
//                                 if (update['file'] != null) {
//                                   _openFileFromURL(update['file']);
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
//                 onView: showDailyUpdateDialog,
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
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';

// ⬇️ for auth token you already use elsewhere (e.g., LiveAttendancePage)
import 'package:serv_app/models/company_data.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  // API base
  static const String _apiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';

  // local preview list (unchanged UI)
  List<PlatformFile> uploadedFiles = [];

  // daily updates (now filled from API)
  List<Map<String, dynamic>> dailyUpdates = [];
  bool isLoadingUpdates = false;

  final bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchDailyUpdates(); // now calls API instead of dummy data
  }

  /// Turn a possibly-relative `/uploads/...` into absolute URL
  String? _absUrl(dynamic maybeUrl) {
    if (maybeUrl == null) return null;
    final u = maybeUrl.toString();
    return u.startsWith('http') ? u : '$_apiBase$u';
  }

  /// ⬇️ CHANGED: Pull real daily updates from backend and map to your dialog shape
  Future<void> fetchDailyUpdates() async {
    setState(() => isLoadingUpdates = true);

    try {
      // If your backend supports `?kind=DailyUpdate`, you can use that.
      // To be fully compatible, we fetch broadcasts and filter on the client.
      final uri = Uri.parse('$_apiBase/api/tasks?audience=all');

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

        // only keep DailyUpdate docs
        final daily = list.where((e) {
          final kind = (e['kind'] ?? '').toString();
          return kind.toLowerCase() == 'dailyupdate';
        }).toList();

        // sort newest first by createdAt
        daily.sort((a, b) {
          final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        // map to the dialog shape you already use
        final mapped = daily.map<Map<String, dynamic>>((e) {
          final file = (e['file'] is Map<String, dynamic>) ? e['file'] : null;
          final title = (e['title'] ?? file?['name'] ?? 'Daily update').toString();
          final createdAt = (e['createdAt'] ?? '').toString();
          final date = createdAt.isNotEmpty && createdAt.contains('T')
              ? createdAt.split('T').first
              : createdAt;

          return {
            "date": date,
            "update": title,
            "timeSpent": "", // not stored; leave blank
            "updatedBy": (e['createdBy'] ?? e['assignedTo'] ?? '').toString(),
            "file": _absUrl(file != null ? file['url'] : null),
          };
        }).toList();

        setState(() {
          dailyUpdates = mapped;
          isLoadingUpdates = false;
        });
      } else {
        setState(() {
          isLoadingUpdates = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch updates: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoadingUpdates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch updates: $e')),
      );
    }
  }

  /// Pick file for "Task assigned" and upload to backend (no UI changes)
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: kIsWeb, // web needs bytes
    );
    if (result == null) return;

    final PlatformFile picked = result.files.single;

    // this page is for admin; keeping existing behavior (local dialog add)
    setState(() => uploadedFiles.add(picked));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ File selected.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void showUploadedFiles(List<PlatformFile> files, String title) {
    showDialog(
      context: context,
      builder: (_) => TaskUploadsDialog(files: files, title: title),
    );
  }

  void showDailyUpdateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Updates", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoadingUpdates
              ? const Center(child: CircularProgressIndicator())
              : dailyUpdates.isEmpty
                  ? const Text("No daily updates yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: dailyUpdates.length,
                      itemBuilder: (ctx, index) {
                        final update = dailyUpdates[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text("📅 ${update['date']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📝 ${update['update']}"),
                                if ((update['timeSpent'] as String).isNotEmpty)
                                  Text("⏱ ${update['timeSpent']}"),
                                if ((update['updatedBy'] as String).isNotEmpty)
                                  Text("👩‍💻 ${update['updatedBy']}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                              onPressed: () {
                                final url = update['file'] as String?;
                                if (url != null && url.isNotEmpty) {
                                  _openFileFromURL(url);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _openFileFromURL(String fileUrl) {
    if (kIsWeb) {
      html.window.open(fileUrl, "_blank");
    } else {
      OpenFilex.open(fileUrl);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              taskSection(
                "Task assigned",
                showUpload: true,
                onUpload: _isUploading ? () {} : () => pickFile(),
                onView: () => showUploadedFiles(uploadedFiles, "Task Uploads"),
              ),
              const SizedBox(height: 30),
              taskSection(
                "Daily Update",
                showUpload: false,
                onUpload: () {},
                onView: showDailyUpdateDialog, // now shows live data
              ),
              const SizedBox(height: 30),
              if (_isUploading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget taskSection(
    String title, {
    required bool showUpload,
    required VoidCallback onUpload,
    required VoidCallback onView,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8E71B7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showUpload)
              ElevatedButton(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5E94),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Upload", style: TextStyle(color: Colors.white)),
              ),
            if (showUpload) const SizedBox(width: 20),
            ElevatedButton(
              onPressed: onView,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5E94),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("View", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

class TaskUploadsDialog extends StatelessWidget {
  final List<PlatformFile> files;
  final String title;

  const TaskUploadsDialog({
    super.key,
    required this.files,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: files.isEmpty
            ? const Center(child: Text("No files uploaded"))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file, size: 30),
                    title: Text(files[index].name),
                    onTap: () async {
                      Navigator.pop(context);
                      if (kIsWeb) {
                        final fileBytes = files[index].bytes;
                        final fileName = files[index].name;
                        if (fileBytes != null) {
                          final blob = html.Blob([fileBytes]);
                          final url = html.Url.createObjectUrlFromBlob(blob);
                          final anchor = html.AnchorElement(href: url)
                            ..target = '_blank'
                            ..download = fileName;
                          anchor.click();
                          html.Url.revokeObjectUrl(url);
                        }
                      } else {
                        if (files[index].path != null) {
                          await OpenFilex.open(files[index].path!);
                        }
                      }
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
        )
      ],
    );
  }
}
