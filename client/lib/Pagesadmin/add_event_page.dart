// import 'dart:typed_data';
// import 'dart:math'; // for UUID generator
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// // ⬇️ Adjust base URL
// const String apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class EventUploadPage extends StatefulWidget {
//   const EventUploadPage({super.key});
//   @override
//   State<EventUploadPage> createState() => _EventUploadPageState();
// }

// class _EventUploadPageState extends State<EventUploadPage> {
//   final nameCtrl = TextEditingController();
//   final fromDateCtrl = TextEditingController();
//   final toDateCtrl = TextEditingController();
//   final locationCtrl = TextEditingController();
//   final descCtrl = TextEditingController();

//   PlatformFile? _image;
//   PlatformFile? _file;

//   @override
//   void dispose() {
//     nameCtrl.dispose(); fromDateCtrl.dispose(); toDateCtrl.dispose();
//     locationCtrl.dispose(); descCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
//     if (r != null && r.files.isNotEmpty) setState(() => _image = r.files.single);
//   }

//   Future<void> _pickFile() async {
//     final r = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
//     if (r != null && r.files.isNotEmpty) setState(() => _file = r.files.single);
//   }

//   Future<void> _pickDate(TextEditingController c) async {
//     final d = await showDatePicker(
//       context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2101),
//     );
//     if (d != null) c.text = DateFormat('yyyy-MM-dd').format(d);
//   }

//   // Minimal, dependency-free UUID v4
//   String _uuidV4() {
//     final rand = Random.secure();
//     final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
//     bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
//     bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant
//     String h(int b) => b.toRadixString(16).padLeft(2, '0');
//     final hex = bytes.map(h).join();
//     return '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-'
//            '${hex.substring(16,20)}-${hex.substring(20)}';
//   }

//   Future<void> _submit() async {
//     // NOTE: Your original screen has no "Event Name *" filled in the screenshot.
//     // Keep validation identical:
//     if (nameCtrl.text.trim().isEmpty ||
//         fromDateCtrl.text.trim().isEmpty ||
//         toDateCtrl.text.trim().isEmpty ||
//         locationCtrl.text.trim().isEmpty ||
//         descCtrl.text.trim().isEmpty ||
//         _image == null) {
//       _toast('Please fill all required fields and upload an image.');
//       return;
//     }

//     try {
//       // Provide a client UUID so server doesn’t call uuidv4()
//       final clientId = _uuidV4();

//       final req = http.MultipartRequest('POST', Uri.parse('$apiBase/events'))
//         ..headers['Accept'] = 'application/json' // don’t set Content-Type manually
//         // send under several common keys so backend can use any of them
//         ..fields['id'] = clientId
//         ..fields['uuid'] = clientId
//         ..fields['eventId'] = clientId
//         ..fields['uid'] = clientId
//         ..fields['title'] = nameCtrl.text.trim()
//         ..fields['description'] = descCtrl.text.trim()
//         ..fields['location'] = locationCtrl.text.trim()
//         ..fields['fromDate'] = fromDateCtrl.text.trim()
//         ..fields['toDate'] = toDateCtrl.text.trim();

//       if (_image?.bytes != null) {
//         req.files.add(http.MultipartFile.fromBytes(
//           'image', _image!.bytes as Uint8List, filename: _image!.name,
//         ));
//       }
//       if (_file?.bytes != null) {
//         req.files.add(http.MultipartFile.fromBytes(
//           'file', _file!.bytes as Uint8List, filename: _file!.name,
//         ));
//       }

//       final resp = await req.send();
//       final body = await resp.stream.bytesToString();

//       if (resp.statusCode == 201) {
//         _toast('Event created.');
//         if (!mounted) return;
//         Navigator.pop(context);
//       } else {
//         _toast('Create failed (${resp.statusCode}): $body');
//       }
//     } catch (e) {
//       _toast('Create error: $e');
//     }
//   }

//   void _toast(String m) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload Event Details'), backgroundColor: kAppBarColor, foregroundColor: kTextColor),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter, end: Alignment.bottomCenter),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             _tf(nameCtrl, label: 'Event Name *'),
//             const SizedBox(height: 10),
//             _tf(fromDateCtrl, label: 'From Date *', readOnly: true, onTap: () => _pickDate(fromDateCtrl)),
//             const SizedBox(height: 10),
//             _tf(toDateCtrl, label: 'To Date *', readOnly: true, onTap: () => _pickDate(toDateCtrl)),
//             const SizedBox(height: 10),
//             _tf(locationCtrl, label: 'Location *'),
//             const SizedBox(height: 10),
//             _tf(descCtrl, label: 'Description *', maxLines: 3),
//             const SizedBox(height: 20),

//             const _LabelWithStar('Upload Event Banner Image'),
//             const SizedBox(height: 6),
//             Row(children: [
//               ElevatedButton.icon(
//                 onPressed: _pickImage,
//                 style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
//                 icon: const Icon(Icons.photo), label: const Text('Upload Image'),
//               ),
//               const SizedBox(width: 10),
//               Text(_image?.name ?? 'No file'),
//             ]),
//             const SizedBox(height: 20),

//             const Text('Upload Related File (PDF, DOC, etc.)', style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             Row(children: [
//               ElevatedButton.icon(
//                 onPressed: _pickFile,
//                 style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
//                 icon: const Icon(Icons.attach_file), label: const Text('Upload File'),
//               ),
//               const SizedBox(width: 10),
//               Text(_file?.name ?? 'No file'),
//             ]),
//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity, height: 50,
//               child: ElevatedButton(
//                 onPressed: _submit,
//                 style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: Colors.white),
//                 child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _tf(TextEditingController c, {required String label, bool readOnly = false, int maxLines = 1, VoidCallback? onTap}) {
//     final hasStar = label.contains('*'); final plain = label.replaceAll('*', '').trim();
//     return TextFormField(
//       controller: c, readOnly: readOnly, maxLines: maxLines, onTap: onTap,
//       decoration: InputDecoration(
//         label: RichText(text: TextSpan(children: [
//           TextSpan(text: plain, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//           if (hasStar) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//         ])),
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
// }

// class _LabelWithStar extends StatelessWidget {
//   final String text; const _LabelWithStar(this.text);
//   @override
//   Widget build(BuildContext context) => RichText(text: TextSpan(children: [
//         TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
//         const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//       ]));
// }
import 'dart:convert';
import 'dart:math'; // for UUID generator
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ⬇️ Adjust base URL if needed
const String apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class EventUploadPage extends StatefulWidget {
  const EventUploadPage({super.key});
  @override
  State<EventUploadPage> createState() => _EventUploadPageState();
}

class _EventUploadPageState extends State<EventUploadPage> {
  final nameCtrl = TextEditingController();
  final fromDateCtrl = TextEditingController();
  final toDateCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    fromDateCtrl.dispose();
    toDateCtrl.dispose();
    locationCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (d != null) c.text = DateFormat('yyyy-MM-dd').format(d);
  }

  // Minimal, dependency-free UUID v4
  String _uuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant
    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(h).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _submit() async {
    // Required fields (image/file are NOT required)
    if (nameCtrl.text.trim().isEmpty ||
        fromDateCtrl.text.trim().isEmpty ||
        toDateCtrl.text.trim().isEmpty ||
        locationCtrl.text.trim().isEmpty ||
        descCtrl.text.trim().isEmpty) {
      _toast('Please fill all required fields.');
      return;
    }

    // Date sanity check
    try {
      final from = DateFormat('yyyy-MM-dd').parse(fromDateCtrl.text.trim());
      final to = DateFormat('yyyy-MM-dd').parse(toDateCtrl.text.trim());
      if (from.isAfter(to)) {
        _toast('From Date cannot be after To Date.');
        return;
      }
    } catch (_) {
      _toast('Dates must be in yyyy-MM-dd format.');
      return;
    }

    try {
      final payload = {
        "id": _uuidV4(),
        "title": nameCtrl.text.trim(),
        "description": descCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "fromDate": fromDateCtrl.text.trim(),
        "toDate": toDateCtrl.text.trim(),
      };

      final resp = await http.post(
        Uri.parse('$apiBase/events'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 201) {
        _toast('Event created.');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _toast('Create failed (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      _toast('Create error: $e');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Event Details'),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tf(nameCtrl, label: 'Event Name *'),
              const SizedBox(height: 10),
              _tf(fromDateCtrl,
                  label: 'From Date *',
                  readOnly: true,
                  onTap: () => _pickDate(fromDateCtrl)),
              const SizedBox(height: 10),
              _tf(toDateCtrl,
                  label: 'To Date *',
                  readOnly: true,
                  onTap: () => _pickDate(toDateCtrl)),
              const SizedBox(height: 10),
              _tf(locationCtrl, label: 'Location *'),
              const SizedBox(height: 10),
              _tf(descCtrl, label: 'Description *', maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      foregroundColor: Colors.white),
                  child: const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController c, {
    required String label,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    final hasStar = label.contains('*');
    final plain = label.replaceAll('*', '').trim();
    return TextFormField(
      controller: c,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: plain,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              if (hasStar)
                const TextSpan(
                  text: ' *',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _LabelWithStar extends StatelessWidget {
  final String text;
  const _LabelWithStar(this.text);
  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
