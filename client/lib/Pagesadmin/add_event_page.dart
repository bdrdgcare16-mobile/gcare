// // // // import 'dart:io';
// // // // import 'package:file_picker/file_picker.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'event_model_page.dart';

// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF); // Light lavender
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9); // Deeper lavender
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;

// // // // class EventUploadPage extends StatefulWidget {
// // // //   const EventUploadPage({super.key});

// // // //   @override
// // // //   State<EventUploadPage> createState() => _EventUploadPageState();
// // // // }

// // // // class _EventUploadPageState extends State<EventUploadPage> {
// // // //   final nameCtrl = TextEditingController();
// // // //   final fromDateCtrl = TextEditingController();
// // // //   final toDateCtrl = TextEditingController();
// // // //   final locationCtrl = TextEditingController();
// // // //   final descCtrl = TextEditingController();

// // // //   File? _image;
// // // //   String? _fileName;

// // // //   Future<void> _pickImage() async {
// // // //     final pickedFile =
// // // //         await ImagePicker().pickImage(source: ImageSource.gallery);
// // // //     if (pickedFile != null) {
// // // //       setState(() {
// // // //         _image = File(pickedFile.path);
// // // //       });
// // // //     }
// // // //   }

// // // //   Future<void> _pickFile() async {
// // // //     FilePickerResult? result = await FilePicker.platform.pickFiles();
// // // //     if (result != null) {
// // // //       setState(() {
// // // //         _fileName = result.files.single.name;
// // // //       });
// // // //     }
// // // //   }

// // // //   Future<void> _selectDate(
// // // //       BuildContext context, TextEditingController controller) async {
// // // //     final DateTime? picked = await showDatePicker(
// // // //       context: context,
// // // //       initialDate: DateTime.now(),
// // // //       firstDate: DateTime(2020),
// // // //       lastDate: DateTime(2101),
// // // //     );
// // // //     if (picked != null) {
// // // //       setState(() {
// // // //         controller.text = DateFormat('yyyy-MM-dd').format(picked);
// // // //       });
// // // //     }
// // // //   }

// // // //   Widget _buildTextField(TextEditingController controller,
// // // //       {required String label,
// // // //       bool readOnly = false,
// // // //       int maxLines = 1,
// // // //       VoidCallback? onTap}) {
// // // //     final labelParts = label.split('*');
// // // //     final mainLabel = labelParts[0].trim();
// // // //     final hasStar = label.contains('*');

// // // //     return TextFormField(
// // // //       controller: controller,
// // // //       readOnly: readOnly,
// // // //       maxLines: maxLines,
// // // //       onTap: onTap,
// // // //       decoration: InputDecoration(
// // // //         label: RichText(
// // // //           text: TextSpan(
// // // //             children: [
// // // //               TextSpan(
// // // //                 text: mainLabel,
// // // //                 style: const TextStyle(
// // // //                   color: Colors.grey,
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //               ),
// // // //               if (hasStar)
// // // //                 const TextSpan(
// // // //                   text: ' *',
// // // //                   style: TextStyle(
// // // //                     color: Colors.red,
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         border: const OutlineInputBorder(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _submitForm() {
// // // //     if (nameCtrl.text.isEmpty ||
// // // //         fromDateCtrl.text.isEmpty ||
// // // //         toDateCtrl.text.isEmpty ||
// // // //         locationCtrl.text.isEmpty ||
// // // //         descCtrl.text.isEmpty) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Please fill all required fields.")),
// // // //       );
// // // //       return;
// // // //     }

// // // //     final event = EventModel(
// // // //       name: nameCtrl.text,
// // // //       fromDate: DateTime.parse(fromDateCtrl.text),
// // // //       toDate: DateTime.parse(toDateCtrl.text),
// // // //       location: locationCtrl.text,
// // // //       description: descCtrl.text,
// // // //       imagePath: _image?.path ?? '',
// // // //     );

// // // //     eventsList.add(event);

// // // //     Navigator.pop(context); // Go back to EventUpdatesPage
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text("Upload Event Details"),
// // // //         backgroundColor: kAppBarColor,
// // // //         foregroundColor: kTextColor,
// // // //       ),
// // // //       body: Container(
// // // //         decoration: const BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // //             begin: Alignment.topCenter,
// // // //             end: Alignment.bottomCenter,
// // // //           ),
// // // //         ),
// // // //         child: SingleChildScrollView(
// // // //           padding: const EdgeInsets.all(16.0),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               _buildTextField(nameCtrl, label: "Event Name *"),
// // // //               const SizedBox(height: 10),
// // // //               _buildTextField(
// // // //                 fromDateCtrl,
// // // //                 label: "From Date *",
// // // //                 readOnly: true,
// // // //                 onTap: () => _selectDate(context, fromDateCtrl),
// // // //               ),
// // // //               const SizedBox(height: 10),
// // // //               _buildTextField(
// // // //                 toDateCtrl,
// // // //                 label: "To Date *",
// // // //                 readOnly: true,
// // // //                 onTap: () => _selectDate(context, toDateCtrl),
// // // //               ),
// // // //               const SizedBox(height: 10),
// // // //               _buildTextField(locationCtrl, label: "Location *"),
// // // //               const SizedBox(height: 10),
// // // //               _buildTextField(descCtrl, label: "Description *", maxLines: 3),
// // // //               const SizedBox(height: 20),

// // // //               const Text(
// // // //                 "Upload Event Banner (Image)",
// // // //                 style: TextStyle(fontWeight: FontWeight.bold),
// // // //               ),
// // // //               const SizedBox(height: 5),
// // // //               Row(
// // // //                 children: [
// // // //                   ElevatedButton.icon(
// // // //                     onPressed: _pickImage,
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: kButtonColor,
// // // //                       foregroundColor: kTextColor,
// // // //                     ),
// // // //                     icon: const Icon(Icons.photo),
// // // //                     label: const Text("Pick Image"),
// // // //                   ),
// // // //                   const SizedBox(width: 10),
// // // //                   if (_image != null)
// // // //                     const Text("Selected", style: TextStyle(color: Colors.green)),
// // // //                 ],
// // // //               ),
// // // //               const SizedBox(height: 20),

// // // //               const Text(
// // // //                 "Upload Related File (PDF, DOC, etc.)",
// // // //                 style: TextStyle(fontWeight: FontWeight.bold),
// // // //               ),
// // // //               const SizedBox(height: 5),
// // // //               Row(
// // // //                 children: [
// // // //                   ElevatedButton.icon(
// // // //                     onPressed: _pickFile,
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: kButtonColor,
// // // //                       foregroundColor: kTextColor,
// // // //                     ),
// // // //                     icon: const Icon(Icons.attach_file),
// // // //                     label: const Text("Pick File"),
// // // //                   ),
// // // //                   const SizedBox(width: 10),
// // // //                   if (_fileName != null) Text(_fileName!),
// // // //                 ],
// // // //               ),
// // // //               const SizedBox(height: 30),

// // // //               Center(
// // // //                 child: Container(
// // // //                   width: double.infinity,
// // // //                   height: 50,
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: const LinearGradient(
// // // //                       colors: [Color(0xFF8C6EAF), Color(0xFF655193)],
// // // //                     ),
// // // //                     borderRadius: BorderRadius.circular(8),
// // // //                   ),
// // // //                   child: ElevatedButton(
// // // //                     onPressed: _submitForm,
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: Colors.transparent,
// // // //                       shadowColor: Colors.transparent,
// // // //                       foregroundColor: Colors.white,
// // // //                     ),
// // // //                     child: const Text(
// // // //                       "Submit",
// // // //                       style: TextStyle(fontWeight: FontWeight.bold),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:io';
// // // import 'package:file_picker/file_picker.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:intl/intl.dart';
// // // import 'event_model_page.dart';

// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF); // Light lavender
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9); // Deeper lavender
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // class EventUploadPage extends StatefulWidget {
// // //   const EventUploadPage({super.key});

// // //   @override
// // //   State<EventUploadPage> createState() => _EventUploadPageState();
// // // }

// // // class _EventUploadPageState extends State<EventUploadPage> {
// // //   final nameCtrl = TextEditingController();
// // //   final fromDateCtrl = TextEditingController();
// // //   final toDateCtrl = TextEditingController();
// // //   final locationCtrl = TextEditingController();
// // //   final descCtrl = TextEditingController();

// // //   File? _image;
// // //   String? _fileName;

// // //   Future<void> _pickImage() async {
// // //     final pickedFile = await ImagePicker().pickImage(
// // //       source: ImageSource.gallery,
// // //     );
// // //     if (pickedFile != null) {
// // //       setState(() {
// // //         _image = File(pickedFile.path);
// // //       });
// // //     }
// // //   }

// // //   Future<void> _pickFile() async {
// // //     FilePickerResult? result = await FilePicker.platform.pickFiles();
// // //     if (result != null) {
// // //       setState(() {
// // //         _fileName = result.files.single.name;
// // //       });
// // //     }
// // //   }

// // //   Future<void> _selectDate(
// // //     BuildContext context,
// // //     TextEditingController controller,
// // //   ) async {
// // //     final DateTime? picked = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now(),
// // //       firstDate: DateTime(2020),
// // //       lastDate: DateTime(2101),
// // //     );
// // //     if (picked != null) {
// // //       if (controller == toDateCtrl && fromDateCtrl.text.isNotEmpty) {
// // //         final fromDate = DateTime.tryParse(fromDateCtrl.text);
// // //         if (fromDate != null && picked.isBefore(fromDate)) {
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             const SnackBar(
// // //               content: Text("To Date cannot be before From Date."),
// // //               backgroundColor: Colors.red,
// // //             ),
// // //           );
// // //           return;
// // //         }
// // //       }

// // //       setState(() {
// // //         controller.text = DateFormat('yyyy-MM-dd').format(picked);
// // //       });
// // //     }
// // //   }

// // //   Widget _buildTextField(
// // //     TextEditingController controller, {
// // //     required String label,
// // //     bool readOnly = false,
// // //     int maxLines = 1,
// // //     VoidCallback? onTap,
// // //   }) {
// // //     final labelParts = label.split('*');
// // //     final mainLabel = labelParts[0].trim();
// // //     final hasStar = label.contains('*');

// // //     return TextFormField(
// // //       controller: controller,
// // //       readOnly: readOnly,
// // //       maxLines: maxLines,
// // //       onTap: onTap,
// // //       decoration: InputDecoration(
// // //         label: RichText(
// // //           text: TextSpan(
// // //             children: [
// // //               TextSpan(
// // //                 text: mainLabel,
// // //                 style: const TextStyle(
// // //                   color: Colors.grey,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //               if (hasStar)
// // //                 const TextSpan(
// // //                   text: ' *',
// // //                   style: TextStyle(
// // //                     color: Colors.red,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //         ),
// // //         border: const OutlineInputBorder(),
// // //       ),
// // //     );
// // //   }

// // //   void _submitForm() {
// // //     if (nameCtrl.text.isEmpty ||
// // //         fromDateCtrl.text.isEmpty ||
// // //         toDateCtrl.text.isEmpty ||
// // //         locationCtrl.text.isEmpty ||
// // //         descCtrl.text.isEmpty ||
// // //         _image == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text("Please fill all required fields and upload an image."),
// // //         ),
// // //       );
// // //       return;
// // //     }

// // //     final event = EventModel(
// // //       name: nameCtrl.text,
// // //       fromDate: DateTime.parse(fromDateCtrl.text),
// // //       toDate: DateTime.parse(toDateCtrl.text),
// // //       location: locationCtrl.text,
// // //       description: descCtrl.text,
// // //       imagePath: _image!.path,
// // //     );

// // //     eventsList.add(event);

// // //     Navigator.pop(context); // Go back to EventUpdatesPage
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Upload Event Details"),
// // //         backgroundColor: kAppBarColor,
// // //         foregroundColor: kTextColor,
// // //       ),
// // //       body: Container(
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //           ),
// // //         ),
// // //         child: SingleChildScrollView(
// // //           padding: const EdgeInsets.all(16.0),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               _buildTextField(nameCtrl, label: "Event Name *"),
// // //               const SizedBox(height: 10),
// // //               _buildTextField(
// // //                 fromDateCtrl,
// // //                 label: "From Date *",
// // //                 readOnly: true,
// // //                 onTap: () => _selectDate(context, fromDateCtrl),
// // //               ),
// // //               const SizedBox(height: 10),
// // //               _buildTextField(
// // //                 toDateCtrl,
// // //                 label: "To Date *",
// // //                 readOnly: true,
// // //                 onTap: () => _selectDate(context, toDateCtrl),
// // //               ),
// // //               const SizedBox(height: 10),
// // //               _buildTextField(locationCtrl, label: "Location *"),
// // //               const SizedBox(height: 10),
// // //               _buildTextField(descCtrl, label: "Description *", maxLines: 3),
// // //               const SizedBox(height: 20),

// // //               // ---------- Image Upload (with red star) ----------
// // //               RichText(
// // //                 text: const TextSpan(
// // //                   children: [
// // //                     TextSpan(
// // //                       text: "Upload Event Banner Image",
// // //                       style: TextStyle(
// // //                         fontWeight: FontWeight.bold,
// // //                         color: Colors.black, // default text color
// // //                       ),
// // //                     ),
// // //                     TextSpan(
// // //                       text: ' *',
// // //                       style: TextStyle(
// // //                         color: Colors.red,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 5),
// // //               Row(
// // //                 children: [
// // //                   ElevatedButton.icon(
// // //                     onPressed: _pickImage,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: kButtonColor,
// // //                       foregroundColor: kTextColor,
// // //                     ),
// // //                     icon: const Icon(Icons.photo),
// // //                     label: const Text("Upload Image"),
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   if (_image != null)
// // //                     const Text(
// // //                       "Selected",
// // //                       style: TextStyle(color: Color.fromARGB(255, 56, 58, 56)),
// // //                     ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 20),

// // //               const Text(
// // //                 "Upload Related File (PDF, DOC, etc.)",
// // //                 style: TextStyle(fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 5),
// // //               Row(
// // //                 children: [
// // //                   ElevatedButton.icon(
// // //                     onPressed: _pickFile,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: kButtonColor,
// // //                       foregroundColor: kTextColor,
// // //                     ),
// // //                     icon: const Icon(Icons.attach_file),
// // //                     label: const Text("Upload File"),
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   if (_fileName != null) Text(_fileName!),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 30),

// // //               Center(
// // //                 child: Container(
// // //                   width: double.infinity,
// // //                   height: 50,
// // //                   decoration: BoxDecoration(
// // //                     gradient: const LinearGradient(
// // //                       colors: [Color(0xFF8C6EAF), Color(0xFF655193)],
// // //                     ),
// // //                     borderRadius: BorderRadius.circular(8),
// // //                   ),
// // //                   child: ElevatedButton(
// // //                     onPressed: _submitForm,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: Colors.transparent,
// // //                       shadowColor: Colors.transparent,
// // //                       foregroundColor: Colors.white,
// // //                     ),
// // //                     child: const Text(
// // //                       "Submit",
// // //                       style: TextStyle(fontWeight: FontWeight.bold),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'dart:typed_data';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';

// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // // Same base URL used in the list page
// // const String apiBase = 'http://localhost:3000/api';

// // class EventUploadPage extends StatefulWidget {
// //   const EventUploadPage({super.key});
// //   @override
// //   State<EventUploadPage> createState() => _EventUploadPageState();
// // }

// // class _EventUploadPageState extends State<EventUploadPage> {
// //   final nameCtrl = TextEditingController();
// //   final fromDateCtrl = TextEditingController();
// //   final toDateCtrl = TextEditingController();
// //   final locationCtrl = TextEditingController();
// //   final descCtrl = TextEditingController();

// //   PlatformFile? _image;       // bytes + name
// //   PlatformFile? _relatedFile; // bytes + name

// //   @override
// //   void dispose() {
// //     nameCtrl.dispose();
// //     fromDateCtrl.dispose();
// //     toDateCtrl.dispose();
// //     locationCtrl.dispose();
// //     descCtrl.dispose();
// //     super.dispose();
// //   }

// //   String _mimeFromName(String name) {
// //     final ext = name.split('.').last.toLowerCase();
// //     switch (ext) {
// //       case 'jpg':
// //       case 'jpeg':
// //         return 'image/jpeg';
// //       case 'png':
// //         return 'image/png';
// //       case 'gif':
// //         return 'image/gif';
// //       case 'pdf':
// //         return 'application/pdf';
// //       case 'xlsx':
// //         return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
// //       case 'xls':
// //         return 'application/vnd.ms-excel';
// //       case 'csv':
// //         return 'text/csv';
// //       case 'doc':
// //         return 'application/msword';
// //       case 'docx':
// //         return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
// //       case 'txt':
// //         return 'text/plain';
// //       default:
// //         return 'application/octet-stream';
// //     }
// //   }

// //   Future<void> _pickImage() async {
// //     final res = await FilePicker.platform.pickFiles(
// //       type: FileType.image,
// //       allowMultiple: false,
// //       withData: true,
// //     );
// //     if (res != null && res.files.isNotEmpty) {
// //       setState(() => _image = res.files.single);
// //     }
// //   }

// //   Future<void> _pickFile() async {
// //     final res = await FilePicker.platform.pickFiles(
// //       allowMultiple: false,
// //       withData: true,
// //     );
// //     if (res != null && res.files.isNotEmpty) {
// //       setState(() => _relatedFile = res.files.single);
// //     }
// //   }

// //   Future<void> _selectDate(BuildContext context, TextEditingController ctrl) async {
// //     final DateTime? picked = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(2020),
// //       lastDate: DateTime(2101),
// //     );
// //     if (picked != null) {
// //       // keep yyyy-MM-dd to match backend
// //       ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
// //     }
// //   }

// //   Future<void> _submitForm() async {
// //     if (nameCtrl.text.trim().isEmpty ||
// //         fromDateCtrl.text.trim().isEmpty ||
// //         toDateCtrl.text.trim().isEmpty ||
// //         locationCtrl.text.trim().isEmpty ||
// //         descCtrl.text.trim().isEmpty ||
// //         _image == null) {
// //       _show('Please fill all required fields and upload an image.');
// //       return;
// //     }

// //     try {
// //       final uri = Uri.parse('$apiBase/events');
// //       final req = http.MultipartRequest('POST', uri)
// //         ..fields['title'] = nameCtrl.text.trim()
// //         ..fields['description'] = descCtrl.text.trim()
// //         ..fields['location'] = locationCtrl.text.trim()
// //         ..fields['fromDate'] = fromDateCtrl.text.trim()
// //         ..fields['toDate'] = toDateCtrl.text.trim();

// //       // Attach image
// //       if (_image?.bytes != null) {
// //         req.files.add(http.MultipartFile.fromBytes(
// //           'image',
// //           _image!.bytes as Uint8List,
// //           filename: _image!.name,
// //         ));
// //       }

// //       // Attach related file (optional)
// //       if (_relatedFile?.bytes != null) {
// //         req.files.add(http.MultipartFile.fromBytes(
// //           'file',
// //           _relatedFile!.bytes as Uint8List,
// //           filename: _relatedFile!.name,
// //         ));
// //       }

// //       final resp = await req.send();
// //       if (resp.statusCode == 201) {
// //         _show('Event created.');
// //         if (!mounted) return;
// //         Navigator.pop(context);
// //       } else {
// //         final body = await resp.stream.bytesToString();
// //         _show('Create failed (${resp.statusCode}): $body');
// //       }
// //     } catch (e) {
// //       _show('Create error: $e');
// //     }
// //   }

// //   void _show(String msg) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Upload Event Details"),
// //         backgroundColor: kAppBarColor,
// //         foregroundColor: kTextColor,
// //       ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.all(16.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               _tf(nameCtrl, label: "Event Name *"),
// //               const SizedBox(height: 10),
// //               _tf(fromDateCtrl,
// //                   label: "From Date *",
// //                   readOnly: true,
// //                   onTap: () => _selectDate(context, fromDateCtrl)),
// //               const SizedBox(height: 10),
// //               _tf(toDateCtrl,
// //                   label: "To Date *",
// //                   readOnly: true,
// //                   onTap: () => _selectDate(context, toDateCtrl)),
// //               const SizedBox(height: 10),
// //               _tf(locationCtrl, label: "Location *"),
// //               const SizedBox(height: 10),
// //               _tf(descCtrl, label: "Description *", maxLines: 3),
// //               const SizedBox(height: 20),

// //               // Image (required)
// //               const _LabelWithStar('Upload Event Banner Image'),
// //               const SizedBox(height: 6),
// //               Row(
// //                 children: [
// //                   ElevatedButton.icon(
// //                     onPressed: _pickImage,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: kButtonColor,
// //                       foregroundColor: kTextColor,
// //                     ),
// //                     icon: const Icon(Icons.photo),
// //                     label: const Text("Upload Image"),
// //                   ),
// //                   const SizedBox(width: 10),
// //                   Text(_image?.name ?? 'No file'),
// //                 ],
// //               ),
// //               const SizedBox(height: 20),

// //               const Text("Upload Related File (PDF, DOC, etc.)",
// //                   style: TextStyle(fontWeight: FontWeight.bold)),
// //               const SizedBox(height: 6),
// //               Row(
// //                 children: [
// //                   ElevatedButton.icon(
// //                     onPressed: _pickFile,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: kButtonColor,
// //                       foregroundColor: kTextColor,
// //                     ),
// //                     icon: const Icon(Icons.attach_file),
// //                     label: const Text("Upload File"),
// //                   ),
// //                   const SizedBox(width: 10),
// //                   Text(_relatedFile?.name ?? 'No file'),
// //                 ],
// //               ),
// //               const SizedBox(height: 30),

// //               SizedBox(
// //                 width: double.infinity,
// //                 height: 50,
// //                 child: ElevatedButton(
// //                   onPressed: _submitForm,
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: kButtonColor,
// //                     foregroundColor: Colors.white,
// //                   ),
// //                   child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _tf(TextEditingController c,
// //       {required String label, bool readOnly = false, int maxLines = 1, VoidCallback? onTap}) {
// //     final hasStar = label.contains('*');
// //     final plain = label.replaceAll('*', '').trim();
// //     return TextFormField(
// //       controller: c,
// //       readOnly: readOnly,
// //       maxLines: maxLines,
// //       onTap: onTap,
// //       decoration: InputDecoration(
// //         label: RichText(
// //           text: TextSpan(children: [
// //             TextSpan(text: plain, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
// //             if (hasStar)
// //               const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
// //           ]),
// //         ),
// //         border: const OutlineInputBorder(),
// //       ),
// //     );
// //   }
// // }

// // class _LabelWithStar extends StatelessWidget {
// //   final String text;
// //   const _LabelWithStar(this.text);
// //   @override
// //   Widget build(BuildContext context) => RichText(
// //         text: TextSpan(children: [
// //           TextSpan(
// //               text: text,
// //               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
// //           const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
// //         ]),
// //       );
// // }
// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// // ⬇️ Adjust base URL
// const String apiBase = 'http://localhost:3000/api';

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

//   Future<void> _submit() async {
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
//       final req = http.MultipartRequest('POST', Uri.parse('$apiBase/events'))
//         ..headers['Accept'] = 'application/json' // do NOT set Content-Type manually
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
//           gradient: LinearGradient(colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
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
import 'dart:typed_data';
import 'dart:math'; // for UUID generator
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ⬇️ Adjust base URL
const String apiBase = 'http://localhost:3000/api';

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

  PlatformFile? _image;
  PlatformFile? _file;

  @override
  void dispose() {
    nameCtrl.dispose(); fromDateCtrl.dispose(); toDateCtrl.dispose();
    locationCtrl.dispose(); descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r != null && r.files.isNotEmpty) setState(() => _image = r.files.single);
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
    if (r != null && r.files.isNotEmpty) setState(() => _file = r.files.single);
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2101),
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
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-'
           '${hex.substring(16,20)}-${hex.substring(20)}';
  }

  Future<void> _submit() async {
    // NOTE: Your original screen has no "Event Name *" filled in the screenshot.
    // Keep validation identical:
    if (nameCtrl.text.trim().isEmpty ||
        fromDateCtrl.text.trim().isEmpty ||
        toDateCtrl.text.trim().isEmpty ||
        locationCtrl.text.trim().isEmpty ||
        descCtrl.text.trim().isEmpty ||
        _image == null) {
      _toast('Please fill all required fields and upload an image.');
      return;
    }

    try {
      // Provide a client UUID so server doesn’t call uuidv4()
      final clientId = _uuidV4();

      final req = http.MultipartRequest('POST', Uri.parse('$apiBase/events'))
        ..headers['Accept'] = 'application/json' // don’t set Content-Type manually
        // send under several common keys so backend can use any of them
        ..fields['id'] = clientId
        ..fields['uuid'] = clientId
        ..fields['eventId'] = clientId
        ..fields['uid'] = clientId
        ..fields['title'] = nameCtrl.text.trim()
        ..fields['description'] = descCtrl.text.trim()
        ..fields['location'] = locationCtrl.text.trim()
        ..fields['fromDate'] = fromDateCtrl.text.trim()
        ..fields['toDate'] = toDateCtrl.text.trim();

      if (_image?.bytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'image', _image!.bytes as Uint8List, filename: _image!.name,
        ));
      }
      if (_file?.bytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'file', _file!.bytes as Uint8List, filename: _file!.name,
        ));
      }

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        _toast('Event created.');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _toast('Create failed (${resp.statusCode}): $body');
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
      appBar: AppBar(title: const Text('Upload Event Details'), backgroundColor: kAppBarColor, foregroundColor: kTextColor),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _tf(nameCtrl, label: 'Event Name *'),
            const SizedBox(height: 10),
            _tf(fromDateCtrl, label: 'From Date *', readOnly: true, onTap: () => _pickDate(fromDateCtrl)),
            const SizedBox(height: 10),
            _tf(toDateCtrl, label: 'To Date *', readOnly: true, onTap: () => _pickDate(toDateCtrl)),
            const SizedBox(height: 10),
            _tf(locationCtrl, label: 'Location *'),
            const SizedBox(height: 10),
            _tf(descCtrl, label: 'Description *', maxLines: 3),
            const SizedBox(height: 20),

            const _LabelWithStar('Upload Event Banner Image'),
            const SizedBox(height: 6),
            Row(children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                icon: const Icon(Icons.photo), label: const Text('Upload Image'),
              ),
              const SizedBox(width: 10),
              Text(_image?.name ?? 'No file'),
            ]),
            const SizedBox(height: 20),

            const Text('Upload Related File (PDF, DOC, etc.)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                icon: const Icon(Icons.attach_file), label: const Text('Upload File'),
              ),
              const SizedBox(width: 10),
              Text(_file?.name ?? 'No file'),
            ]),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: Colors.white),
                child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, {required String label, bool readOnly = false, int maxLines = 1, VoidCallback? onTap}) {
    final hasStar = label.contains('*'); final plain = label.replaceAll('*', '').trim();
    return TextFormField(
      controller: c, readOnly: readOnly, maxLines: maxLines, onTap: onTap,
      decoration: InputDecoration(
        label: RichText(text: TextSpan(children: [
          TextSpan(text: plain, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          if (hasStar) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ])),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _LabelWithStar extends StatelessWidget {
  final String text; const _LabelWithStar(this.text);
  @override
  Widget build(BuildContext context) => RichText(text: TextSpan(children: [
        TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ]));
}
