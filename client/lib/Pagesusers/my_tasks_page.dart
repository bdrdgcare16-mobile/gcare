import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Preview/open helpers
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:excel/excel.dart' as xls;

import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;

// 🔐 pull auth/empid like your other pages
import 'package:serv_app/models/company_data.dart';
import 'package:http/http.dart' as http;

/* ================= CONFIG ================= */
const String _apiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';

/* ================= THEME ================= */
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/* ============== MODEL (API) ============== */
class _TaskItem {
  final String id;
  final String title;
  final String? description;
  final String audience; // "all" | "employee"
  final String? assignedTo;
  final String? createdAt;
  final _TaskFile? file;

  _TaskItem({
    required this.id,
    required this.title,
    required this.audience,
    this.description,
    this.assignedTo,
    this.createdAt,
    this.file,
  });

  factory _TaskItem.fromJson(Map<String, dynamic> j) => _TaskItem(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: j['description']?.toString(),
        audience: (j['audience'] ?? 'all').toString(),
        assignedTo: j['assignedTo']?.toString(),
        createdAt: j['createdAt']?.toString(),
        file: j['file'] is Map<String, dynamic> ? _TaskFile.fromJson(j['file']) : null,
      );
}

class _TaskFile {
  final String name;
  final int? size;
  final String? contentType;
  final String url; // may be "/uploads/.."

  _TaskFile({required this.name, required this.url, this.size, this.contentType});

  factory _TaskFile.fromJson(Map<String, dynamic> j) => _TaskFile(
        name: (j['name'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        size: j['size'] is num ? (j['size'] as num).toInt() : null,
        contentType: j['contentType']?.toString(),
      );
}

/* ============== PAGE ============== */
class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  File? _imageFile;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isImage = true;

  // API state
  bool _loadingTasks = false;
  String? _tasksError;
  List<_TaskItem> _tasks = [];

  // upload state
  bool _uploading = false;

  // quick helpers for local (Daily Update) file preview
  bool get _isPdf => (_fileName ?? '').toLowerCase().endsWith('.pdf');
  bool get _isExcel {
    final n = (_fileName ?? '').toLowerCase();
    return n.endsWith('.xls') || n.endsWith('.xlsx');
  }
  bool get _isCsv => (_fileName ?? '').toLowerCase().endsWith('.csv');

  /* ------------ CAPTURE (Camera) ------------ */
  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      // read bytes for upload (works on web & mobile)
      final bytes = kIsWeb
          ? await pickedImage.readAsBytes()
          : await File(pickedImage.path).readAsBytes();

      setState(() {
        _imageFile = kIsWeb ? null : File(pickedImage.path); // preview only
        _fileBytes = bytes;
        _fileName = pickedImage.name.isNotEmpty
            ? pickedImage.name
            : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        _isImage = true;
      });

      // 🔗 send to backend as DailyUpdate
      await _sendDailyUpdate(_fileBytes!, _fileName!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image captured from camera successfully")),
        );
      }
    }
  }

  /* ------------ PICK FILE (Daily Update) ------------ */
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      final name = result.files.single.name;
      final bytes = result.files.single.bytes!;
      final ext = name.split('.').last.toLowerCase();
      setState(() {
        _fileBytes = bytes;
        _imageFile = null;
        _fileName = name;
        _isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
      });

      // 🔗 send to backend as DailyUpdate
      await _sendDailyUpdate(bytes, name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File selected")),
        );
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Choose File'),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
        ],
      ),
    );
  }

  /* ============== SEND DAILY UPDATE TO BACKEND ============== */
  // New behavior:
  // - If empid is present -> POST /api/tasks/upload (assignedTo=empid)
  // - If empid missing -> POST /api/tasks/broadcast (no assignedTo)
  Future<void> _sendDailyUpdate(Uint8List data, String filename) async {
    if (_uploading) return;

    setState(() => _uploading = true);

    try {
      final empid = (CompanyData.empid ?? '').trim();
      final hasEmp = empid.isNotEmpty;

      final uri = hasEmp
          ? Uri.parse('$_apiBase/tasks/upload')
          : Uri.parse('$_apiBase/tasks/broadcast');

      final req = http.MultipartRequest('POST', uri);

      if ((CompanyData.token ?? '').isNotEmpty) {
        req.headers['Authorization'] = 'Bearer ${CompanyData.token}';
      }

      // Common fields
      req.fields['title'] = filename;
      req.fields['description'] = 'Daily update';
      req.fields['kind'] = 'DailyUpdate';

      // Only for personal upload
      if (hasEmp) {
        req.fields['assignedTo'] = empid;
      }

      // file part
      req.files.add(
        http.MultipartFile.fromBytes('file', data, filename: filename),
      );

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasEmp ? 'Daily update uploaded' : 'Uploaded (broadcast mode)',
              ),
            ),
          );
        }
        // force a refresh next time user opens "View Task"
        _tasks.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed (${resp.statusCode}): $body')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /* =================== API: fetch tasks for this employee =================== */
  Future<void> _fetchTasksIfNeeded() async {
    if (_tasks.isNotEmpty || _loadingTasks) return;
    setState(() {
      _loadingTasks = true;
      _tasksError = null;
    });

    // Prefer employee endpoint; fall back to audience=all (broadcast only)
    final empid = (CompanyData.empid ?? '').trim();
    Uri uri = empid.isNotEmpty
        ? Uri.parse('$_apiBase/tasks?empid=$empid')
        : Uri.parse('$_apiBase/tasks?audience=all');

    // ✅ renamed from `try` (reserved) to `_tryFetch`
    Future<bool> tryFetch(Uri u) async {
      final resp = await http.get(
        u,
        headers: {
          'Content-Type': 'application/json',
          if ((CompanyData.token ?? '').isNotEmpty) 'Authorization': 'Bearer ${CompanyData.token}',
        },
      );

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        final list = data.map((e) => _TaskItem.fromJson(e as Map<String, dynamic>)).toList();

        // sort locally by createdAt desc
        list.sort((a, b) {
          final ad = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        setState(() => _tasks = list);
        return true;
      } else {
        setState(() => _tasksError = 'Error ${resp.statusCode}: ${resp.body}');
        return false;
      }
    }

    try {
      final ok = await tryFetch(uri);
      if (!ok && empid.isNotEmpty) {
        await tryFetch(Uri.parse('$_apiBase/tasks?audience=all'));
      }
    } catch (e) {
      setState(() => _tasksError = 'Failed to fetch tasks: $e');
    } finally {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  /* =================== OPEN a task file =================== */
  Future<void> _openTaskFile(_TaskItem t) async {
    if (t.file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file attached')),
      );
      return;
    }
    var url = t.file!.url;
    if (!url.startsWith('http')) url = '$_apiBase$url';

    if (kIsWeb) {
      html.window.open(url, '_blank');
      return;
    }

    try {
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        final bytes = r.bodyBytes;
        final dir = await getTemporaryDirectory();
        final safeName = t.file!.name.isNotEmpty ? t.file!.name : 'task_${t.id}';
        final f = File('${dir.path}/$safeName');
        await f.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(f.path);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file (${r.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e')),
      );
    }
  }

  /* ------------ VIEW: Daily Update local preview ------------ */
  void _viewUploadedContent() async {
    if (_imageFile != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Uploaded Image"),
          content: Image.file(_imageFile!, fit: BoxFit.cover),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
        ),
      );
      return;
    }

    if (_fileBytes != null && _fileName != null) {
      if (_isImage) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_fileName!),
            content: Image.memory(_fileBytes!, fit: BoxFit.cover),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
          ),
        );
        return;
      }

      if (_isPdf) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _PdfViewerFromBytes(name: _fileName!, bytes: _fileBytes!)),
        );
        return;
      }

      if (_isExcel) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _ExcelViewerFromBytes(name: _fileName!, bytes: _fileBytes!)),
        );
        return;
      }

      if (_isCsv) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _CsvViewerFromBytes(name: _fileName!, bytes: _fileBytes!)),
        );
        return;
      }

      final path = await _ensureTempFile(_fileName!, _fileBytes!);
      await OpenFilex.open(path);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No file selected")));
  }

  Future<String> _ensureTempFile(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /* ------------ “Task Assigned” button → show tasks list ------------ */
  Future<void> _viewTaskDetails() async {
    await _fetchTasksIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Task Assigned"),
        content: SizedBox(
          width: double.maxFinite,
          child: _loadingTasks
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _tasksError != null
                  ? Text(_tasksError!)
                  : _tasks.isEmpty
                      ? const Text("No tasks available.")
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = _tasks[i];
                            return ListTile(
                              leading: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                              title: Text(t.title.isNotEmpty ? t.title : (t.file?.name ?? 'Task')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (t.createdAt != null) Text(t.createdAt!),
                                  if (t.audience == 'employee' && t.assignedTo != null)
                                    Text('Assigned to: ${t.assignedTo}'),
                                ],
                              ),
                              onTap: () => _openTaskFile(t),
                            );
                          },
                        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  /* ------------ UI (unchanged visually) ------------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tasks"), backgroundColor: kAppBarColor),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Task Assigned",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _viewTaskDetails,
                style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                child: const Text("View Task"),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Daily Update Upload",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _showUploadOptions,
                    style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                    child: const Text("Upload"),
                  ),
                  ElevatedButton(
                    onPressed: _viewUploadedContent,
                    style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                    child: const Text("View"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_imageFile != null || (_fileBytes != null && _isImage))
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_fileBytes!, fit: BoxFit.cover)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Minimal PDF viewer (bytes) ---------- */
class _PdfViewerFromBytes extends StatefulWidget {
  final String name;
  final Uint8List bytes;
  const _PdfViewerFromBytes({required this.name, required this.bytes});

  @override
  State<_PdfViewerFromBytes> createState() => _PdfViewerFromBytesState();
}

class _PdfViewerFromBytesState extends State<_PdfViewerFromBytes> {
  late PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(document: PdfDocument.openData(widget.bytes));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name), backgroundColor: kAppBarColor),
      body: PdfView(controller: _controller),
    );
  }
}

/* ---------- Minimal Excel viewer (bytes) ---------- */
class _ExcelViewerFromBytes extends StatelessWidget {
  final String name;
  final Uint8List bytes;
  const _ExcelViewerFromBytes({required this.name, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final book = xls.Excel.decodeBytes(bytes);
    final sheetNames = book.tables.keys.toList();

    return DefaultTabController(
      length: sheetNames.isEmpty ? 1 : sheetNames.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: kAppBarColor,
          bottom: TabBar(
            isScrollable: true,
            tabs: (sheetNames.isEmpty ? [const Tab(text: 'Sheet1')] : sheetNames.map((s) => Tab(text: s)).toList()),
          ),
        ),
        body: TabBarView(
          children: (sheetNames.isEmpty
              ? [const Center(child: Text('No sheets found'))]
              : sheetNames.map((s) {
                  final t = book.tables[s]!;
                  final rows = t.maxRows;
                  final cols = t.maxRows; // ✅ correct column count

                  final colCount = cols.clamp(1, 12);
                  final rowCount = rows.clamp(0, 200);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                      columns: List.generate(colCount, (c) => DataColumn(label: Text('C${c + 1}'))),
                      rows: List.generate(rowCount, (r) {
                        return DataRow(
                          cells: List.generate(colCount, (c) {
                            final cell = t.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
                            final v = cell.value?.toString() ?? '';
                            return DataCell(SizedBox(width: 120, child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis)));
                          }),
                        );
                      }),
                    ),
                  );
                }).toList()),
        ),
      ),
    );
  }
}

/* ---------- Minimal CSV viewer (bytes) ---------- */
class _CsvViewerFromBytes extends StatelessWidget {
  final String name;
  final Uint8List bytes;
  const _CsvViewerFromBytes({required this.name, required this.bytes});

  List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    int i = 0;
    List<String> row = [];
    final sb = StringBuffer();
    bool inQuotes = false;

    void endField() {
      row.add(sb.toString());
      sb.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = [];
    }

    while (i < text.length) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            sb.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          sb.write(ch);
          i++;
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
          i++;
        } else if (ch == ',') {
          endField();
          i++;
        } else if (ch == '\r') {
          i++;
        } else if (ch == '\n') {
          endRow();
          i++;
        } else {
          sb.write(ch);
          i++;
        }
      }
    }
    if (sb.isNotEmpty || row.isNotEmpty) endRow();

    if (rows.isNotEmpty && rows.every((r) => r.length <= 1)) {
      final lines = const LineSplitter().convert(text);
      final delim = _bestDelimiter(lines);
      return lines.map((l) => l.split(delim)).toList();
    }
    return rows;
  }

  String _bestDelimiter(List<String> lines) {
    final sample = lines.take(5).toList();
    final counts = {
      ',': sample.map((l) => l.split(',').length).fold<int>(0, (a, b) => a + b),
      ';': sample.map((l) => l.split(';').length).fold<int>(0, (a, b) => a + b),
      '\t': sample.map((l) => l.split('\t').length).fold<int>(0, (a, b) => a + b),
    };
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final table = _parseCsv(text);

    final rowCount = table.length.clamp(0, 200);
    final colCount =
        (table.isNotEmpty ? table.map((r) => r.length).reduce((a, b) => a > b ? a : b) : 0).clamp(0, 12);

    return Scaffold(
      appBar: AppBar(title: Text(name), backgroundColor: kAppBarColor),
      body: table.isEmpty
          ? const Center(child: Text('No data'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                columns: List.generate(colCount, (c) => DataColumn(label: Text('C${c + 1}'))),
                rows: List.generate(rowCount, (r) {
                  final row = r < table.length ? table[r] : const <String>[];
                  return DataRow(
                    cells: List.generate(colCount, (c) {
                      final v = c < row.length ? row[c] : '';
                      return DataCell(SizedBox(width: 160, child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis)));
                    }),
                  );
                }),
              ),
            ),
    );
  }
}
