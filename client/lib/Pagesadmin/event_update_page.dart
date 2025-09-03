

// // // // // // import 'dart:convert';
// // // // // // import 'dart:html' as html;
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'event_model_page.dart';
// // // // // // import 'add_event_page.dart';

// // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // const Color kTextColor = Colors.white;

// // // // // // class EventUpdatesPage extends StatefulWidget {
// // // // // //   const EventUpdatesPage({super.key});

// // // // // //   @override
// // // // // //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // // // // // }

// // // // // // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// // // // // //   List<EventModel> filteredEvents = eventsList;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       backgroundColor: kPrimaryBackgroundBottom,
// // // // // //       appBar: AppBar(
// // // // // //         backgroundColor: kAppBarColor,
// // // // // //         title: const Text('Event Updates'),
// // // // // //         actions: [
// // // // // //           TextButton.icon(
// // // // // //             onPressed: _startSearch,
// // // // // //             icon: const Icon(Icons.search, color: kTextColor),
// // // // // //             label: const Text('Search', style: TextStyle(color: kTextColor)),
// // // // // //           ),
// // // // // //           TextButton.icon(
// // // // // //             onPressed: _downloadAsDocument,
// // // // // //             icon: const Icon(Icons.download, color: kTextColor),
// // // // // //             label: const Text('Download', style: TextStyle(color: kTextColor)),
// // // // // //           ),
// // // // // //           ElevatedButton(
// // // // // //             onPressed: () async {
// // // // // //               await Navigator.push(
// // // // // //                 context,
// // // // // //                 MaterialPageRoute(builder: (context) => const EventUploadPage()),
// // // // // //               );
// // // // // //               setState(() {
// // // // // //                 filteredEvents = eventsList;
// // // // // //               });
// // // // // //             },
// // // // // //             style: ElevatedButton.styleFrom(
// // // // // //               backgroundColor: kButtonColor,
// // // // // //               foregroundColor: kTextColor,
// // // // // //             ),
// // // // // //             child: const Text('Add'),
// // // // // //           ),
// // // // // //           const SizedBox(width: 8),
// // // // // //         ],
// // // // // //       ),
// // // // // //       body: Padding(
// // // // // //         padding: const EdgeInsets.all(12),
// // // // // //         child: Container(
// // // // // //           decoration: BoxDecoration(
// // // // // //             color: Colors.white,
// // // // // //             borderRadius: BorderRadius.circular(10),
// // // // // //           ),
// // // // // //           child: SingleChildScrollView(
// // // // // //             scrollDirection: Axis.horizontal,
// // // // // //             child: SizedBox(
// // // // // //               width: 900,
// // // // // //               child: Column(
// // // // // //                 children: [
// // // // // //                   Container(
// // // // // //                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // // // // //                     color: kPrimaryBackgroundBottom.withOpacity(0.5),
// // // // // //                     child: Row(
// // // // // //                       children: const [
// // // // // //                         _HeaderCell('Event Name', width: 120),
// // // // // //                         _HeaderCell('From Date', width: 120),
// // // // // //                         _HeaderCell('To Date', width: 120),
// // // // // //                         _HeaderCell('Location', width: 120),
// // // // // //                         _HeaderCell('Image Upload', width: 120),
// // // // // //                         _HeaderCell('Description', width: 120),
// // // // // //                         _HeaderCell('Delete', width: 50),
// // // // // //                       ],
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const Divider(height: 1, thickness: 1),
// // // // // //                   Expanded(
// // // // // //                     child: filteredEvents.isEmpty
// // // // // //                         ? const Center(child: Text('No data found'))
// // // // // //                         : ListView.builder(
// // // // // //                             itemCount: filteredEvents.length,
// // // // // //                             itemBuilder: (context, index) {
// // // // // //                               final event = filteredEvents[index];
// // // // // //                               return Container(
// // // // // //                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // // // // //                                 decoration: BoxDecoration(
// // // // // //                                   border: Border(
// // // // // //                                     bottom: BorderSide(color: Colors.grey.shade300),
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                                 child: Row(
// // // // // //                                   children: [
// // // // // //                                     _BodyCell(event.name, width: 120),
// // // // // //                                     _BodyCell(event.fromDate.toString().split(' ')[0], width: 120),
// // // // // //                                     _BodyCell(event.toDate.toString().split(' ')[0], width: 120),
// // // // // //                                     _BodyCell(event.location, width: 120),
// // // // // //                                     _BodyCell(event.imagePath.isNotEmpty ? '✔' : '', width: 120),
// // // // // //                                     _BodyCell(event.description, width: 120),
// // // // // //                                     SizedBox(
// // // // // //                                       width: 50,
// // // // // //                                       child: IconButton(
// // // // // //                                         icon: const Icon(Icons.delete, color: Colors.red),
// // // // // //                                         onPressed: () => _confirmDelete(index),
// // // // // //                                       ),
// // // // // //                                     ),
// // // // // //                                   ],
// // // // // //                                 ),
// // // // // //                               );
// // // // // //                             },
// // // // // //                           ),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   void _startSearch() {
// // // // // //     String localQuery = '';
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       builder: (context) {
// // // // // //         return AlertDialog(
// // // // // //           title: const Text('Search Events'),
// // // // // //           content: TextField(
// // // // // //             autofocus: true,
// // // // // //             decoration: const InputDecoration(hintText: 'Enter event name'),
// // // // // //             onChanged: (value) {
// // // // // //               localQuery = value;
// // // // // //             },
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             TextButton(
// // // // // //               onPressed: () {
// // // // // //                 setState(() {
// // // // // //                   filteredEvents = eventsList
// // // // // //                       .where((e) => e.name.toLowerCase().contains(localQuery.toLowerCase()))
// // // // // //                       .toList();
// // // // // //                 });
// // // // // //                 Navigator.of(context).pop();
// // // // // //               },
// // // // // //               child: const Text('Search'),
// // // // // //             ),
// // // // // //             TextButton(
// // // // // //               onPressed: () {
// // // // // //                 setState(() {
// // // // // //                   filteredEvents = eventsList;
// // // // // //                 });
// // // // // //                 Navigator.of(context).pop();
// // // // // //               },
// // // // // //               child: const Text('Clear'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   void _downloadAsDocument() {
// // // // // //     final buffer = StringBuffer();
// // // // // //     for (var event in filteredEvents) {
// // // // // //       buffer.writeln('Event Name: ${event.name}');
// // // // // //       buffer.writeln('From: ${event.fromDate.toString().split(' ')[0]}');
// // // // // //       buffer.writeln('To: ${event.toDate.toString().split(' ')[0]}');
// // // // // //       buffer.writeln('Location: ${event.location}');
// // // // // //       buffer.writeln('Image: ${event.imagePath.isNotEmpty ? '✔' : 'No'}');
// // // // // //       buffer.writeln('Description: ${event.description}');
// // // // // //       buffer.writeln('---');
// // // // // //     }

// // // // // //     final bytes = utf8.encode(buffer.toString());
// // // // // //     final blob = html.Blob([bytes]);
// // // // // //     final url = html.Url.createObjectUrlFromBlob(blob);
// // // // // //     final anchor = html.AnchorElement(href: url)
// // // // // //       ..setAttribute("download", "event_updates.txt")
// // // // // //       ..click();
// // // // // //     html.Url.revokeObjectUrl(url);
// // // // // //   }

// // // // // //   void _confirmDelete(int index) {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       builder: (context) => AlertDialog(
// // // // // //         title: const Text('Confirm Delete'),
// // // // // //         content: const Text('Are you sure you want to delete this event?'),
// // // // // //         actions: [
// // // // // //           TextButton(
// // // // // //             child: const Text('Cancel'),
// // // // // //             onPressed: () => Navigator.of(context).pop(),
// // // // // //           ),
// // // // // //           TextButton(
// // // // // //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// // // // // //             onPressed: () {
// // // // // //               setState(() {
// // // // // //                 eventsList.removeAt(index);
// // // // // //                 filteredEvents = eventsList;
// // // // // //               });
// // // // // //               Navigator.of(context).pop();
// // // // // //             },
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _HeaderCell extends StatelessWidget {
// // // // // //   final String label;
// // // // // //   final double width;
// // // // // //   const _HeaderCell(this.label, {required this.width});

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return SizedBox(
// // // // // //       width: width,
// // // // // //       child: Text(
// // // // // //         label,
// // // // // //         style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _BodyCell extends StatelessWidget {
// // // // // //   final String text;
// // // // // //   final double width;
// // // // // //   const _BodyCell(this.text, {required this.width});

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return SizedBox(
// // // // // //       width: width,
// // // // // //       child: Text(
// // // // // //         text,
// // // // // //         overflow: TextOverflow.ellipsis,
// // // // // //         maxLines: 1,
// // // // // //         style: const TextStyle(wordSpacing: 2.0),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // // import 'dart:convert';
// // // // // // import 'dart:html' as html;
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'event_model_page.dart';
// // // // // // import 'add_event_page.dart';

// // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // const Color kTextColor = Colors.white;

// // // // // // class EventUpdatesPage extends StatefulWidget {
// // // // // //   const EventUpdatesPage({super.key});

// // // // // //   @override
// // // // // //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // // // // // }

// // // // // // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// // // // // //   List<EventModel> filteredEvents = eventsList;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       backgroundColor: kPrimaryBackgroundBottom,
// // // // // //       appBar: AppBar(
// // // // // //         backgroundColor: kAppBarColor,
// // // // // //         title: const Text('Event Updates', style: TextStyle(color: kTextColor)),
// // // // // //         iconTheme: const IconThemeData(color: kTextColor),
// // // // // //       ),
// // // // // //       body: Padding(
// // // // // //         padding: const EdgeInsets.all(12),
// // // // // //         child: Column(
// // // // // //           children: [
// // // // // //             // 🔹 Button Row below AppBar
// // // // // //             Row(
// // // // // //               mainAxisAlignment: MainAxisAlignment.end,
// // // // // //               children: [
// // // // // //                 TextButton.icon(
// // // // // //                   onPressed: _startSearch,
// // // // // //                   icon: const Icon(Icons.search, color: kButtonColor),
// // // // // //                   label: const Text('Search', style: TextStyle(color: kButtonColor)),
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 8),
// // // // // //                 TextButton.icon(
// // // // // //                   onPressed: _downloadAsDocument,
// // // // // //                   icon: const Icon(Icons.download, color: kButtonColor),
// // // // // //                   label: const Text('Download', style: TextStyle(color: kButtonColor)),
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 8),
// // // // // //                 ElevatedButton(
// // // // // //                   onPressed: () async {
// // // // // //                     await Navigator.push(
// // // // // //                       context,
// // // // // //                       MaterialPageRoute(builder: (context) => const EventUploadPage()),
// // // // // //                     );
// // // // // //                     setState(() {
// // // // // //                       filteredEvents = eventsList;
// // // // // //                     });
// // // // // //                   },
// // // // // //                   style: ElevatedButton.styleFrom(
// // // // // //                     backgroundColor: kButtonColor,
// // // // // //                     foregroundColor: kTextColor,
// // // // // //                   ),
// // // // // //                   child: const Text('Add'),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //             const SizedBox(height: 12),

// // // // // //             // 🔹 Table content
// // // // // //             Expanded(
// // // // // //               child: Container(
// // // // // //                 decoration: BoxDecoration(
// // // // // //                   color: Colors.white,
// // // // // //                   borderRadius: BorderRadius.circular(10),
// // // // // //                 ),
// // // // // //                 child: SingleChildScrollView(
// // // // // //                   scrollDirection: Axis.horizontal,
// // // // // //                   child: SizedBox(
// // // // // //                     width: 900,
// // // // // //                     child: Column(
// // // // // //                       children: [
// // // // // //                         Container(
// // // // // //                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // // // // //                           color: kPrimaryBackgroundBottom.withOpacity(0.5),
// // // // // //                           child: Row(
// // // // // //                             children: const [
// // // // // //                               _HeaderCell('Event Name', width: 120),
// // // // // //                               _HeaderCell('From Date', width: 120),
// // // // // //                               _HeaderCell('To Date', width: 120),
// // // // // //                               _HeaderCell('Location', width: 120),
// // // // // //                               _HeaderCell('Image Upload', width: 120),
// // // // // //                               _HeaderCell('Description', width: 120),
// // // // // //                               _HeaderCell('Delete', width: 50),
// // // // // //                             ],
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                         const Divider(height: 1, thickness: 1),
// // // // // //                         Expanded(
// // // // // //                           child: filteredEvents.isEmpty
// // // // // //                               ? const Center(child: Text('No data found'))
// // // // // //                               : ListView.builder(
// // // // // //                                   itemCount: filteredEvents.length,
// // // // // //                                   itemBuilder: (context, index) {
// // // // // //                                     final event = filteredEvents[index];
// // // // // //                                     return Container(
// // // // // //                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // // // // //                                       decoration: BoxDecoration(
// // // // // //                                         border: Border(
// // // // // //                                           bottom: BorderSide(color: Colors.grey.shade300),
// // // // // //                                         ),
// // // // // //                                       ),
// // // // // //                                       child: Row(
// // // // // //                                         children: [
// // // // // //                                           _BodyCell(event.name, width: 120),
// // // // // //                                           _BodyCell(event.fromDate.toString().split(' ')[0], width: 120),
// // // // // //                                           _BodyCell(event.toDate.toString().split(' ')[0], width: 120),
// // // // // //                                           _BodyCell(event.location, width: 120),
// // // // // //                                           _BodyCell(event.imagePath.isNotEmpty ? '✔' : '', width: 120),
// // // // // //                                           _BodyCell(event.description, width: 120),
// // // // // //                                           SizedBox(
// // // // // //                                             width: 50,
// // // // // //                                             child: IconButton(
// // // // // //                                               icon: const Icon(Icons.delete, color: Colors.red),
// // // // // //                                               onPressed: () => _confirmDelete(index),
// // // // // //                                             ),
// // // // // //                                           ),
// // // // // //                                         ],
// // // // // //                                       ),
// // // // // //                                     );
// // // // // //                                   },
// // // // // //                                 ),
// // // // // //                         ),
// // // // // //                       ],
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   void _startSearch() {
// // // // // //     String localQuery = '';
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       builder: (context) {
// // // // // //         return AlertDialog(
// // // // // //           title: const Text('Search Events'),
// // // // // //           content: TextField(
// // // // // //             autofocus: true,
// // // // // //             decoration: const InputDecoration(hintText: 'Enter event name'),
// // // // // //             onChanged: (value) {
// // // // // //               localQuery = value;
// // // // // //             },
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             TextButton(
// // // // // //               onPressed: () {
// // // // // //                 setState(() {
// // // // // //                   filteredEvents = eventsList
// // // // // //                       .where((e) => e.name.toLowerCase().contains(localQuery.toLowerCase()))
// // // // // //                       .toList();
// // // // // //                 });
// // // // // //                 Navigator.of(context).pop();
// // // // // //               },
// // // // // //               child: const Text('Search'),
// // // // // //             ),
// // // // // //             TextButton(
// // // // // //               onPressed: () {
// // // // // //                 setState(() {
// // // // // //                   filteredEvents = eventsList;
// // // // // //                 });
// // // // // //                 Navigator.of(context).pop();
// // // // // //               },
// // // // // //               child: const Text('Clear'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   void _downloadAsDocument() {
// // // // // //     final buffer = StringBuffer();
// // // // // //     for (var event in filteredEvents) {
// // // // // //       buffer.writeln('Event Name: ${event.name}');
// // // // // //       buffer.writeln('From: ${event.fromDate.toString().split(' ')[0]}');
// // // // // //       buffer.writeln('To: ${event.toDate.toString().split(' ')[0]}');
// // // // // //       buffer.writeln('Location: ${event.location}');
// // // // // //       buffer.writeln('Image: ${event.imagePath.isNotEmpty ? '✔' : 'No'}');
// // // // // //       buffer.writeln('Description: ${event.description}');
// // // // // //       buffer.writeln('---');
// // // // // //     }

// // // // // //     final bytes = utf8.encode(buffer.toString());
// // // // // //     final blob = html.Blob([bytes]);
// // // // // //     final url = html.Url.createObjectUrlFromBlob(blob);
// // // // // //     final anchor = html.AnchorElement(href: url)
// // // // // //       ..setAttribute("download", "event_updates.txt")
// // // // // //       ..click();
// // // // // //     html.Url.revokeObjectUrl(url);
// // // // // //   }

// // // // // //   void _confirmDelete(int index) {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       builder: (context) => AlertDialog(
// // // // // //         title: const Text('Confirm Delete'),
// // // // // //         content: const Text('Are you sure you want to delete this event?'),
// // // // // //         actions: [
// // // // // //           TextButton(
// // // // // //             child: const Text('Cancel'),
// // // // // //             onPressed: () => Navigator.of(context).pop(),
// // // // // //           ),
// // // // // //           TextButton(
// // // // // //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// // // // // //             onPressed: () {
// // // // // //               setState(() {
// // // // // //                 eventsList.removeAt(index);
// // // // // //                 filteredEvents = eventsList;
// // // // // //               });
// // // // // //               Navigator.of(context).pop();
// // // // // //             },
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _HeaderCell extends StatelessWidget {
// // // // // //   final String label;
// // // // // //   final double width;
// // // // // //   const _HeaderCell(this.label, {required this.width});

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return SizedBox(
// // // // // //       width: width,
// // // // // //       child: Text(
// // // // // //         label,
// // // // // //         style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _BodyCell extends StatelessWidget {
// // // // // //   final String text;
// // // // // //   final double width;
// // // // // //   const _BodyCell(this.text, {required this.width});

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return SizedBox(
// // // // // //       width: width,
// // // // // //       child: Text(
// // // // // //         text,
// // // // // //         overflow: TextOverflow.ellipsis,
// // // // // //         maxLines: 1,
// // // // // //         style: const TextStyle(wordSpacing: 2.0),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'dart:convert';
// // // // // import 'dart:html' as html;
// // // // // import 'package:flutter/material.dart';
// // // // // import 'event_model_page.dart';
// // // // // import 'add_event_page.dart';

// // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // const Color kTextColor = Colors.white;

// // // // // class EventUpdatesPage extends StatefulWidget {
// // // // //   const EventUpdatesPage({super.key});

// // // // //   @override
// // // // //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // // // // }

// // // // // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// // // // //   List<EventModel> filteredEvents = eventsList;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor: kPrimaryBackgroundBottom,
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: kAppBarColor,
// // // // //         title: const Text('Event Updates'),
// // // // //         actions: [
// // // // //           TextButton.icon(
// // // // //             onPressed: _startSearch,
// // // // //             icon: const Icon(Icons.search, color: kTextColor),
// // // // //             label: const Text('Search', style: TextStyle(color: kTextColor)),
// // // // //           ),
// // // // //           TextButton.icon(
// // // // //             onPressed: _downloadAsDocument,
// // // // //             icon: const Icon(Icons.download, color: kTextColor),
// // // // //             label: const Text('Download', style: TextStyle(color: kTextColor)),
// // // // //           ),
// // // // //           ElevatedButton(
// // // // //             onPressed: () async {
// // // // //               await Navigator.push(
// // // // //                 context,
// // // // //                 MaterialPageRoute(builder: (context) => const EventUploadPage()),
// // // // //               );
// // // // //               setState(() {
// // // // //                 filteredEvents = eventsList;
// // // // //               });
// // // // //             },
// // // // //             style: ElevatedButton.styleFrom(
// // // // //               backgroundColor: kButtonColor,
// // // // //               foregroundColor: kTextColor,
// // // // //             ),
// // // // //             child: const Text('Add'),
// // // // //           ),
// // // // //           const SizedBox(width: 8),
// // // // //         ],
// // // // //       ),
// // // // //       body: Padding(
// // // // //         padding: const EdgeInsets.all(12),
// // // // //         child: Container(
// // // // //           decoration: BoxDecoration(
// // // // //             color: Colors.white,
// // // // //             borderRadius: BorderRadius.circular(10),
// // // // //           ),
// // // // //           child: SingleChildScrollView(
// // // // //             scrollDirection: Axis.horizontal,
// // // // //             child: SizedBox(
// // // // //               width: 900,
// // // // //               child: Column(
// // // // //                 children: [
// // // // //                   Container(
// // // // //                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // // // //                     color: kPrimaryBackgroundBottom.withOpacity(0.5),
// // // // //                     child: Row(
// // // // //                       children: const [
// // // // //                         _HeaderCell('Event Name', width: 120),
// // // // //                         _HeaderCell('From Date', width: 120),
// // // // //                         _HeaderCell('To Date', width: 120),
// // // // //                         _HeaderCell('Location', width: 120),
// // // // //                         _HeaderCell('Image Upload', width: 120),
// // // // //                         _HeaderCell('Description', width: 120),
// // // // //                         _HeaderCell('Delete', width: 50),
// // // // //                       ],
// // // // //                     ),
// // // // //                   ),
// // // // //                   const Divider(height: 1, thickness: 1),
// // // // //                   Expanded(
// // // // //                     child: filteredEvents.isEmpty
// // // // //                         ? const Center(child: Text('No data found'))
// // // // //                         : ListView.builder(
// // // // //                             itemCount: filteredEvents.length,
// // // // //                             itemBuilder: (context, index) {
// // // // //                               final event = filteredEvents[index];
// // // // //                               return Container(
// // // // //                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // // // //                                 decoration: BoxDecoration(
// // // // //                                   border: Border(
// // // // //                                     bottom: BorderSide(color: Colors.grey.shade300),
// // // // //                                   ),
// // // // //                                 ),
// // // // //                                 child: Row(
// // // // //                                   children: [
// // // // //                                     _BodyCell(event.name, width: 120),
// // // // //                                     _BodyCell(event.fromDate.toString().split(' ')[0], width: 120),
// // // // //                                     _BodyCell(event.toDate.toString().split(' ')[0], width: 120),
// // // // //                                     _BodyCell(event.location, width: 120),
// // // // //                                     _BodyCell(event.imagePath.isNotEmpty ? '✔' : '', width: 120),
// // // // //                                     _BodyCell(event.description, width: 120),
// // // // //                                     SizedBox(
// // // // //                                       width: 50,
// // // // //                                       child: IconButton(
// // // // //                                         icon: const Icon(Icons.delete, color: Colors.red),
// // // // //                                         onPressed: () => _confirmDelete(index),
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ],
// // // // //                                 ),
// // // // //                               );
// // // // //                             },
// // // // //                           ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   void _startSearch() {
// // // // //     String localQuery = '';
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       builder: (context) {
// // // // //         return AlertDialog(
// // // // //           title: const Text('Search Events'),
// // // // //           content: TextField(
// // // // //             autofocus: true,
// // // // //             decoration: const InputDecoration(hintText: 'Enter event name'),
// // // // //             onChanged: (value) {
// // // // //               localQuery = value;
// // // // //             },
// // // // //           ),
// // // // //           actions: [
// // // // //             TextButton(
// // // // //               onPressed: () {
// // // // //                 setState(() {
// // // // //                   filteredEvents = eventsList
// // // // //                       .where((e) => e.name.toLowerCase().contains(localQuery.toLowerCase()))
// // // // //                       .toList();
// // // // //                 });
// // // // //                 Navigator.of(context).pop();
// // // // //               },
// // // // //               child: const Text('Search'),
// // // // //             ),
// // // // //             TextButton(
// // // // //               onPressed: () {
// // // // //                 setState(() {
// // // // //                   filteredEvents = eventsList;
// // // // //                 });
// // // // //                 Navigator.of(context).pop();
// // // // //               },
// // // // //               child: const Text('Clear'),
// // // // //             ),
// // // // //           ],
// // // // //         );
// // // // //       },
// // // // //     );
// // // // //   }

// // // // //   // ✅ CSV Download
// // // // //   void _downloadAsDocument() {
// // // // //     final buffer = StringBuffer();

// // // // //     // CSV header
// // // // //     buffer.writeln('Event Name,From Date,To Date,Location,Image,Description');

// // // // //     for (var event in filteredEvents) {
// // // // //       final name = event.name.replaceAll(',', ' ');
// // // // //       final fromDate = event.fromDate.toString().split(' ')[0];
// // // // //       final toDate = event.toDate.toString().split(' ')[0];
// // // // //       final location = event.location.replaceAll(',', ' ');
// // // // //       final image = event.imagePath.isNotEmpty ? '✔' : 'No';
// // // // //       final description = event.description.replaceAll(',', ' ');

// // // // //       buffer.writeln('$name,$fromDate,$toDate,$location,$image,$description');
// // // // //     }

// // // // //     final bytes = utf8.encode(buffer.toString());
// // // // //     final blob = html.Blob([bytes], 'text/csv');
// // // // //     final url = html.Url.createObjectUrlFromBlob(blob);
// // // // //     final anchor = html.AnchorElement(href: url)
// // // // //       ..setAttribute("download", "event_updates.csv")
// // // // //       ..click();
// // // // //     html.Url.revokeObjectUrl(url);
// // // // //   }

// // // // //   void _confirmDelete(int index) {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       builder: (context) => AlertDialog(
// // // // //         title: const Text('Confirm Delete'),
// // // // //         content: const Text('Are you sure you want to delete this event?'),
// // // // //         actions: [
// // // // //           TextButton(
// // // // //             child: const Text('Cancel'),
// // // // //             onPressed: () => Navigator.of(context).pop(),
// // // // //           ),
// // // // //           TextButton(
// // // // //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// // // // //             onPressed: () {
// // // // //               setState(() {
// // // // //                 eventsList.removeAt(index);
// // // // //                 filteredEvents = eventsList;
// // // // //               });
// // // // //               Navigator.of(context).pop();
// // // // //             },
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _HeaderCell extends StatelessWidget {
// // // // //   final String label;
// // // // //   final double width;
// // // // //   const _HeaderCell(this.label, {required this.width});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SizedBox(
// // // // //       width: width,
// // // // //       child: Text(
// // // // //         label,
// // // // //         style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _BodyCell extends StatelessWidget {
// // // // //   final String text;
// // // // //   final double width;
// // // // //   const _BodyCell(this.text, {required this.width});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SizedBox(
// // // // //       width: width,
// // // // //       child: Text(
// // // // //         text,
// // // // //         overflow: TextOverflow.ellipsis,
// // // // //         maxLines: 1,
// // // // //         style: const TextStyle(wordSpacing: 2.0),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // import 'dart:convert';
// // // // import 'dart:html' as html;
// // // // import 'package:flutter/material.dart';
// // // // import 'event_model_page.dart';
// // // // import 'add_event_page.dart';

// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;

// // // // class EventUpdatesPage extends StatefulWidget {
// // // //   const EventUpdatesPage({super.key});

// // // //   @override
// // // //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // // // }

// // // // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// // // //   List<EventModel> filteredEvents = eventsList;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: kPrimaryBackgroundBottom,
// // // //       appBar: AppBar(
// // // //         backgroundColor: kAppBarColor,
// // // //         leading: IconButton(
// // // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // // //           onPressed: () => Navigator.pop(context),
// // // //         ),
// // // //         title: const Text(
// // // //           'Event Updates',
// // // //           style: TextStyle(color: kTextColor),
// // // //         ),
// // // //         actions: [
// // // //           IconButton(
// // // //             icon: const Icon(Icons.search, color: kTextColor),
// // // //             onPressed: _startSearch,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       body: Padding(
// // // //         padding: const EdgeInsets.all(12),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.end,
// // // //           children: [
// // // //             // 🔽 Add & Download Buttons below AppBar
// // // //             Row(
// // // //               mainAxisAlignment: MainAxisAlignment.end,
// // // //               children: [
// // // //                 ElevatedButton.icon(
// // // //                   onPressed: _downloadAsDocument,
// // // //                   style: ElevatedButton.styleFrom(
// // // //                     backgroundColor: Colors.white,
// // // //                     foregroundColor: kAppBarColor,
// // // //                     elevation: 2,
// // // //                   ),
// // // //                   icon: const Icon(Icons.download),
// // // //                   label: const Text("Download"),
// // // //                 ),
// // // //                 const SizedBox(width: 10),
// // // //                 ElevatedButton.icon(
// // // //                   onPressed: () async {
// // // //                     await Navigator.push(
// // // //                       context,
// // // //                       MaterialPageRoute(builder: (context) => const EventUploadPage()),
// // // //                     );
// // // //                     setState(() {
// // // //                       filteredEvents = eventsList;
// // // //                     });
// // // //                   },
// // // //                   style: ElevatedButton.styleFrom(
// // // //                     backgroundColor: kButtonColor,
// // // //                     foregroundColor: kTextColor,
// // // //                   ),
// // // //                   icon: const Icon(Icons.add),
// // // //                   label: const Text("Add"),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             const SizedBox(height: 10),

// // // //             // 🔽 Table of Event Data
// // // //             Expanded(
// // // //               child: Container(
// // // //                 decoration: BoxDecoration(
// // // //                   color: Colors.white,
// // // //                   borderRadius: BorderRadius.circular(10),
// // // //                 ),
// // // //                 child: SingleChildScrollView(
// // // //                   scrollDirection: Axis.horizontal,
// // // //                   child: SizedBox(
// // // //                     width: 900,
// // // //                     child: Column(
// // // //                       children: [
// // // //                         Container(
// // // //                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // // //                           color: kPrimaryBackgroundBottom.withOpacity(0.5),
// // // //                           child: Row(
// // // //                             children: const [
// // // //                               _HeaderCell('Event Name', width: 120),
// // // //                               _HeaderCell('From Date', width: 120),
// // // //                               _HeaderCell('To Date', width: 120),
// // // //                               _HeaderCell('Location', width: 120),
// // // //                               _HeaderCell('Image Upload', width: 120),
// // // //                               _HeaderCell('Description', width: 120),
// // // //                               _HeaderCell('Delete', width: 50),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                         const Divider(height: 1, thickness: 1),
// // // //                         Expanded(
// // // //                           child: filteredEvents.isEmpty
// // // //                               ? const Center(child: Text('No data found'))
// // // //                               : ListView.builder(
// // // //                                   itemCount: filteredEvents.length,
// // // //                                   itemBuilder: (context, index) {
// // // //                                     final event = filteredEvents[index];
// // // //                                     return Container(
// // // //                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // // //                                       decoration: BoxDecoration(
// // // //                                         border: Border(
// // // //                                           bottom: BorderSide(color: Colors.grey.shade300),
// // // //                                         ),
// // // //                                       ),
// // // //                                       child: Row(
// // // //                                         children: [
// // // //                                           _BodyCell(event.name, width: 120),
// // // //                                           _BodyCell(event.fromDate.toString().split(' ')[0], width: 120),
// // // //                                           _BodyCell(event.toDate.toString().split(' ')[0], width: 120),
// // // //                                           _BodyCell(event.location, width: 120),
// // // //                                           _BodyCell(event.imagePath.isNotEmpty ? '✔' : '', width: 120),
// // // //                                           _BodyCell(event.description, width: 120),
// // // //                                           SizedBox(
// // // //                                             width: 50,
// // // //                                             child: IconButton(
// // // //                                               icon: const Icon(Icons.delete, color: Colors.red),
// // // //                                               onPressed: () => _confirmDelete(index),
// // // //                                             ),
// // // //                                           ),
// // // //                                         ],
// // // //                                       ),
// // // //                                     );
// // // //                                   },
// // // //                                 ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _startSearch() {
// // // //     String localQuery = '';
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) {
// // // //         return AlertDialog(
// // // //           title: const Text('Search Events'),
// // // //           content: TextField(
// // // //             autofocus: true,
// // // //             decoration: const InputDecoration(hintText: 'Enter event name'),
// // // //             onChanged: (value) {
// // // //               localQuery = value;
// // // //             },
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () {
// // // //                 setState(() {
// // // //                   filteredEvents = eventsList
// // // //                       .where((e) => e.name.toLowerCase().contains(localQuery.toLowerCase()))
// // // //                       .toList();
// // // //                 });
// // // //                 Navigator.of(context).pop();
// // // //               },
// // // //               child: const Text('Search'),
// // // //             ),
// // // //             TextButton(
// // // //               onPressed: () {
// // // //                 setState(() {
// // // //                   filteredEvents = eventsList;
// // // //                 });
// // // //                 Navigator.of(context).pop();
// // // //               },
// // // //               child: const Text('Clear'),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }

// // // //   void _downloadAsDocument() {
// // // //     final buffer = StringBuffer();
// // // //     buffer.writeln('Event Name,From Date,To Date,Location,Image,Description');

// // // //     for (var event in filteredEvents) {
// // // //       final name = event.name.replaceAll(',', ' ');
// // // //       final fromDate = event.fromDate.toString().split(' ')[0];
// // // //       final toDate = event.toDate.toString().split(' ')[0];
// // // //       final location = event.location.replaceAll(',', ' ');
// // // //       final image = event.imagePath.isNotEmpty ? '✔' : 'No';
// // // //       final description = event.description.replaceAll(',', ' ');

// // // //       buffer.writeln('$name,$fromDate,$toDate,$location,$image,$description');
// // // //     }

// // // //     final bytes = utf8.encode(buffer.toString());
// // // //     final blob = html.Blob([bytes], 'text/csv');
// // // //     final url = html.Url.createObjectUrlFromBlob(blob);
// // // //     final anchor = html.AnchorElement(href: url)
// // // //       ..setAttribute("download", "event_updates.csv")
// // // //       ..click();
// // // //     html.Url.revokeObjectUrl(url);
// // // //   }

// // // //   void _confirmDelete(int index) {
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) => AlertDialog(
// // // //         title: const Text('Confirm Delete'),
// // // //         content: const Text('Are you sure you want to delete this event?'),
// // // //         actions: [
// // // //           TextButton(
// // // //             child: const Text('Cancel'),
// // // //             onPressed: () => Navigator.of(context).pop(),
// // // //           ),
// // // //           TextButton(
// // // //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// // // //             onPressed: () {
// // // //               setState(() {
// // // //                 eventsList.removeAt(index);
// // // //                 filteredEvents = eventsList;
// // // //               });
// // // //               Navigator.of(context).pop();
// // // //             },
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _HeaderCell extends StatelessWidget {
// // // //   final String label;
// // // //   final double width;
// // // //   const _HeaderCell(this.label, {required this.width});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return SizedBox(
// // // //       width: width,
// // // //       child: Text(
// // // //         label,
// // // //         style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _BodyCell extends StatelessWidget {
// // // //   final String text;
// // // //   final double width;
// // // //   const _BodyCell(this.text, {required this.width});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return SizedBox(
// // // //       width: width,
// // // //       child: Text(
// // // //         text,
// // // //         overflow: TextOverflow.ellipsis,
// // // //         maxLines: 1,
// // // //         style: const TextStyle(wordSpacing: 2.0),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // import 'dart:convert';
// // // import 'dart:html' as html;
// // // import 'package:flutter/material.dart';
// // // import 'event_model_page.dart';
// // // import 'add_event_page.dart';

// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // class EventUpdatesPage extends StatefulWidget {
// // //   const EventUpdatesPage({super.key});

// // //   @override
// // //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // // }

// // // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// // //   List<EventModel> filteredEvents = eventsList;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: kPrimaryBackgroundBottom,
// // //       appBar: AppBar(
// // //         backgroundColor: kAppBarColor,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //         title: const Text('Event Updates', style: TextStyle(color: kTextColor)),
// // //         actions: [
// // //           IconButton(
// // //             icon: const Icon(Icons.search, color: kTextColor),
// // //             onPressed: _startSearch,
// // //           ),
// // //         ],
// // //       ),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(12),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.end,
// // //           children: [
// // //             Row(
// // //               mainAxisAlignment: MainAxisAlignment.end,
// // //               children: [
// // //                 // ✅ Download button without white background
// // //                 ElevatedButton.icon(
// // //                   onPressed: _downloadAsDocument,
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: kButtonColor,
// // //                     foregroundColor: kTextColor,
// // //                   ),
// // //                   icon: const Icon(Icons.download),
// // //                   label: const Text("Download"),
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 ElevatedButton.icon(
// // //                   onPressed: () async {
// // //                     await Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(builder: (context) => const EventUploadPage()),
// // //                     );
// // //                     setState(() {
// // //                       filteredEvents = eventsList;
// // //                     });
// // //                   },
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: kButtonColor,
// // //                     foregroundColor: kTextColor,
// // //                   ),
// // //                   icon: const Icon(Icons.add),
// // //                   label: const Text("Add"),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 10),

// // //             Expanded(
// // //               child: Container(
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(10),
// // //                 ),
// // //                 child: SingleChildScrollView(
// // //                   scrollDirection: Axis.horizontal,
// // //                   child: SizedBox(
// // //                     width: 900,
// // //                     child: Column(
// // //                       children: [
// // //                         Container(
// // //                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// // //                           color: kPrimaryBackgroundBottom.withOpacity(0.5),
// // //                           child: Row(
// // //                             children: const [
// // //                               _HeaderCell('Event Name', width: 120),
// // //                               _HeaderCell('From Date', width: 120),
// // //                               _HeaderCell('To Date', width: 120),
// // //                               _HeaderCell('Location', width: 120),
// // //                               _HeaderCell('Image Upload', width: 120),
// // //                               _HeaderCell('Description', width: 120),
// // //                               _HeaderCell('Delete', width: 50),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         const Divider(height: 1, thickness: 1),
// // //                         Expanded(
// // //                           child: filteredEvents.isEmpty
// // //                               ? const Center(child: Text('No data found'))
// // //                               : ListView.builder(
// // //                                   itemCount: filteredEvents.length,
// // //                                   itemBuilder: (context, index) {
// // //                                     final event = filteredEvents[index];
// // //                                     return Container(
// // //                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // //                                       decoration: BoxDecoration(
// // //                                         border: Border(
// // //                                           bottom: BorderSide(color: Colors.grey.shade300),
// // //                                         ),
// // //                                       ),
// // //                                       child: Row(
// // //                                         children: [
// // //                                           _BodyCell(event.name, width: 120),
// // //                                           _BodyCell(event.fromDate.toString().split(' ')[0], width: 120),
// // //                                           _BodyCell(event.toDate.toString().split(' ')[0], width: 120),
// // //                                           _BodyCell(event.location, width: 120),
// // //                                           _BodyCell(event.imagePath.isNotEmpty ? '✔' : '', width: 120),
// // //                                           _BodyCell(event.description, width: 120),
// // //                                           SizedBox(
// // //                                             width: 50,
// // //                                             child: IconButton(
// // //                                               icon: const Icon(Icons.delete, color: Colors.red),
// // //                                               onPressed: () => _confirmDelete(index),
// // //                                             ),
// // //                                           ),
// // //                                         ],
// // //                                       ),
// // //                                     );
// // //                                   },
// // //                                 ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   void _startSearch() {
// // //     String localQuery = '';
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return AlertDialog(
// // //           title: const Text('Search Events'),
// // //           content: TextField(
// // //             autofocus: true,
// // //             decoration: const InputDecoration(hintText: 'Enter event name'),
// // //             onChanged: (value) {
// // //               localQuery = value;
// // //             },
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () {
// // //                 setState(() {
// // //                   filteredEvents = eventsList
// // //                       .where((e) => e.name.toLowerCase().contains(localQuery.toLowerCase()))
// // //                       .toList();
// // //                 });
// // //                 Navigator.of(context).pop();
// // //               },
// // //               child: const Text('Search'),
// // //             ),
// // //             TextButton(
// // //               onPressed: () {
// // //                 setState(() {
// // //                   filteredEvents = eventsList;
// // //                 });
// // //                 Navigator.of(context).pop();
// // //               },
// // //               child: const Text('Clear'),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }

// // //   void _downloadAsDocument() {
// // //     final buffer = StringBuffer();
// // //     buffer.writeln('Event Name,From Date,To Date,Location,Image,Description');

// // //     for (var event in filteredEvents) {
// // //       final name = event.name.replaceAll(',', ' ');
// // //       final fromDate = event.fromDate.toString().split(' ')[0];
// // //       final toDate = event.toDate.toString().split(' ')[0];
// // //       final location = event.location.replaceAll(',', ' ');
// // //       final image = event.imagePath.isNotEmpty ? '✔' : 'No';
// // //       final description = event.description.replaceAll(',', ' ');

// // //       buffer.writeln('$name,$fromDate,$toDate,$location,$image,$description');
// // //     }

// // //     final bytes = utf8.encode(buffer.toString());
// // //     final blob = html.Blob([bytes], 'text/csv');
// // //     final url = html.Url.createObjectUrlFromBlob(blob);
// // //     final anchor = html.AnchorElement(href: url)
// // //       ..setAttribute("download", "event_updates.csv")
// // //       ..click();
// // //     html.Url.revokeObjectUrl(url);
// // //   }

// // //   void _confirmDelete(int index) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) => AlertDialog(
// // //         title: const Text('Confirm Delete'),
// // //         content: const Text('Are you sure you want to delete this event?'),
// // //         actions: [
// // //           TextButton(
// // //             child: const Text('Cancel'),
// // //             onPressed: () => Navigator.of(context).pop(),
// // //           ),
// // //           TextButton(
// // //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// // //             onPressed: () {
// // //               setState(() {
// // //                 eventsList.removeAt(index);
// // //                 filteredEvents = eventsList;
// // //               });
// // //               Navigator.of(context).pop();
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _HeaderCell extends StatelessWidget {
// // //   final String label;
// // //   final double width;
// // //   const _HeaderCell(this.label, {required this.width});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return SizedBox(
// // //       width: width,
// // //       child: Text(
// // //         label,
// // //         style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _BodyCell extends StatelessWidget {
// // //   final String text;
// // //   final double width;
// // //   const _BodyCell(this.text, {required this.width});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return SizedBox(
// // //       width: width,
// // //       child: Text(
// // //         text,
// // //         overflow: TextOverflow.ellipsis,
// // //         maxLines: 1,
// // //         style: const TextStyle(wordSpacing: 2.0),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'dart:convert';
// // import 'dart:html' as html; // web-only helpers for CSV + opening links
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;

// // import 'event_model_page.dart';
// // import 'add_event_page.dart';

// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // // ⬇️ Set your backend base URL here
// // const String apiBase = 'https://us-central1-servappbackend.cloudfunctions.net/api';

// // class EventUpdatesPage extends StatefulWidget {
// //   const EventUpdatesPage({super.key});

// //   @override
// //   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// // }

// // class _EventUpdatesPageState extends State<EventUpdatesPage> {
// //   List<EventModel> filteredEvents = [];
// //   bool _loading = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadEvents();
// //   }

// //   Future<void> _loadEvents() async {
// //     setState(() => _loading = true);
// //     try {
// //       final resp = await http.get(Uri.parse('$apiBase/events'));
// //       if (resp.statusCode == 200) {
// //         final List data = jsonDecode(resp.body) as List;
// //         eventsList = data.map((e) => EventModel.fromJson(e)).toList();
// //         setState(() => filteredEvents = List.of(eventsList));
// //       } else {
// //         _show('Failed to load events (${resp.statusCode})');
// //       }
// //     } catch (e) {
// //       _show('Load error: $e');
// //     } finally {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }

// //   void _show(String msg) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: kPrimaryBackgroundBottom,
// //       appBar: AppBar(
// //         backgroundColor: kAppBarColor,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text('Event Updates', style: TextStyle(color: kTextColor)),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.search, color: kTextColor),
// //             onPressed: _startSearch,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.refresh, color: kTextColor),
// //             onPressed: _loadEvents,
// //           ),
// //         ],
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(12),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.end,
// //           children: [
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.end,
// //               children: [
// //                 ElevatedButton.icon(
// //                   onPressed: _downloadAsCsv,
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: kButtonColor,
// //                     foregroundColor: kTextColor,
// //                   ),
// //                   icon: const Icon(Icons.download),
// //                   label: const Text("Download"),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 ElevatedButton.icon(
// //                   onPressed: () async {
// //                     await Navigator.push(
// //                       context,
// //                       MaterialPageRoute(builder: (_) => const EventUploadPage()),
// //                     );
// //                     await _loadEvents(); // refresh after returning
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: kButtonColor,
// //                     foregroundColor: kTextColor,
// //                   ),
// //                   icon: const Icon(Icons.add),
// //                   label: const Text("Add"),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             Expanded(
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //                 child: _loading
// //                     ? const Center(child: CircularProgressIndicator())
// //                     : SingleChildScrollView(
// //                         scrollDirection: Axis.horizontal,
// //                         child: SizedBox(
// //                           width: 980,
// //                           child: Column(
// //                             children: [
// //                               Container(
// //                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// //                                 color: kPrimaryBackgroundBottom.withOpacity(0.5),
// //                                 child: Row(
// //                                   children: const [
// //                                     _HeaderCell('Event Name', width: 160),
// //                                     _HeaderCell('From Date', width: 120),
// //                                     _HeaderCell('To Date', width: 120),
// //                                     _HeaderCell('Location', width: 150),
// //                                     _HeaderCell('Image', width: 80),
// //                                     _HeaderCell('Description', width: 260),
// //                                     _HeaderCell('Delete', width: 60),
// //                                   ],
// //                                 ),
// //                               ),
// //                               const Divider(height: 1, thickness: 1),
// //                               Expanded(
// //                                 child: filteredEvents.isEmpty
// //                                     ? const Center(child: Text('No data found'))
// //                                     : ListView.builder(
// //                                         itemCount: filteredEvents.length,
// //                                         itemBuilder: (context, index) {
// //                                           final e = filteredEvents[index];
// //                                           return Container(
// //                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// //                                             decoration: BoxDecoration(
// //                                               border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
// //                                             ),
// //                                             child: Row(
// //                                               children: [
// //                                                 _BodyCell(e.title, width: 160),
// //                                                 _BodyCell(e.fromDate.toIso8601String().split('T').first, width: 120),
// //                                                 _BodyCell(e.toDate.toIso8601String().split('T').first, width: 120),
// //                                                 _BodyCell(e.location, width: 150),
// //                                                 SizedBox(
// //                                                   width: 80,
// //                                                   child: (e.imageUrl ?? '').isEmpty
// //                                                       ? const SizedBox.shrink()
// //                                                       : TextButton(
// //                                                           onPressed: () => html.window.open(e.imageUrl!, '_blank'),
// //                                                           child: const Text('View'),
// //                                                         ),
// //                                                 ),
// //                                                 _BodyCell(e.description, width: 260),
// //                                                 SizedBox(
// //                                                   width: 60,
// //                                                   child: IconButton(
// //                                                     icon: const Icon(Icons.delete, color: Colors.red),
// //                                                     onPressed: () => _confirmDelete(e),
// //                                                   ),
// //                                                 ),
// //                                               ],
// //                                             ),
// //                                           );
// //                                         },
// //                                       ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   void _startSearch() {
// //     String q = '';
// //     showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text('Search Events'),
// //         content: TextField(
// //           autofocus: true,
// //           decoration: const InputDecoration(hintText: 'Enter event name'),
// //           onChanged: (v) => q = v,
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               setState(() {
// //                 filteredEvents = eventsList
// //                     .where((e) => e.title.toLowerCase().contains(q.toLowerCase()))
// //                     .toList();
// //               });
// //               Navigator.pop(context);
// //             },
// //             child: const Text('Search'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               setState(() => filteredEvents = List.of(eventsList));
// //               Navigator.pop(context);
// //             },
// //             child: const Text('Clear'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _downloadAsCsv() {
// //     final buffer = StringBuffer()..writeln('Event Name,From Date,To Date,Location,Image,Description');
// //     for (final e in filteredEvents) {
// //       final m = e.toCsvMap();
// //       buffer.writeln(
// //           '${m['Event Name']},${m['From Date']},${m['To Date']},${m['Location']},${m['Image']},${m['Description']}');
// //     }
// //     final bytes = utf8.encode(buffer.toString());
// //     final blob = html.Blob([bytes], 'text/csv');
// //     final url = html.Url.createObjectUrlFromBlob(blob);
// //     final a = html.AnchorElement(href: url)..setAttribute('download', 'event_updates.csv')..click();
// //     html.Url.revokeObjectUrl(url);
// //   }

// //   Future<void> _confirmDelete(EventModel e) async {
// //     final ok = await showDialog<bool>(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text('Confirm Delete'),
// //         content: Text('Delete "${e.title}"?'),
// //         actions: [
// //           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
// //           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
// //         ],
// //       ),
// //     );
// //     if (ok != true) return;

// //     try {
// //       final resp = await http.delete(Uri.parse('$apiBase/events/${e.id}'));
// //       if (resp.statusCode == 200) {
// //         _show('Deleted');
// //         await _loadEvents();
// //       } else {
// //         _show('Delete failed (${resp.statusCode})');
// //       }
// //     } catch (err) {
// //       _show('Delete error: $err');
// //     }
// //   }
// // }

// // class _HeaderCell extends StatelessWidget {
// //   final String label;
// //   final double width;
// //   const _HeaderCell(this.label, {required this.width});
// //   @override
// //   Widget build(BuildContext context) => SizedBox(
// //         width: width,
// //         child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, wordSpacing: 2.0)),
// //       );
// // }

// // class _BodyCell extends StatelessWidget {
// //   final String text;
// //   final double width;
// //   const _BodyCell(this.text, {required this.width});
// //   @override
// //   Widget build(BuildContext context) => SizedBox(
// //         width: width,
// //         child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(wordSpacing: 2.0)),
// //       );
// // }
// import 'dart:convert';
// import 'dart:html' as html;
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import 'event_model_page.dart';
// import 'add_event_page.dart';

// // ⬇️ Adjust if your server URL differs
// const String apiBase = 'https://us-central1-servappbackend.cloudfunctions.net/api';

// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class EventUpdatesPage extends StatefulWidget {
//   const EventUpdatesPage({super.key});
//   @override
//   State<EventUpdatesPage> createState() => _EventUpdatesPageState();
// }

// class _EventUpdatesPageState extends State<EventUpdatesPage> {
//   List<EventModel> filtered = [];
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final r = await http.get(Uri.parse('$apiBase/events'));
//       if (r.statusCode == 200) {
//         final List data = jsonDecode(r.body);
//         eventsList = data.map((e) => EventModel.fromJson(e)).toList();
//         setState(() => filtered = List.of(eventsList));
//       } else {
//         _toast('Load failed: ${r.statusCode}');
//       }
//     } catch (e) {
//       _toast('Load error: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   void _toast(String m) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundBottom,
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextColor), onPressed: () => Navigator.pop(context)),
//         title: const Text('Event Updates', style: TextStyle(color: kTextColor)),
//         actions: [
//           IconButton(icon: const Icon(Icons.search, color: kTextColor), onPressed: _search),
//           IconButton(icon: const Icon(Icons.refresh, color: kTextColor), onPressed: _load),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _downloadCsv,
//                   style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
//                   icon: const Icon(Icons.download),
//                   label: const Text("Download"),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventUploadPage()));
//                     await _load();
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
//                   icon: const Icon(Icons.add),
//                   label: const Text("Add"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
//                 child: _loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: SizedBox(
//                           width: 980,
//                           child: Column(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                                 color: kPrimaryBackgroundBottom.withOpacity(0.5),
//                                 child: Row(
//                                   children: const [
//                                     _HeaderCell('Event Name', width: 160),
//                                     _HeaderCell('From Date', width: 120),
//                                     _HeaderCell('To Date', width: 120),
//                                     _HeaderCell('Location', width: 150),
//                                     _HeaderCell('Image', width: 80),
//                                     _HeaderCell('Description', width: 260),
//                                     _HeaderCell('Delete', width: 60),
//                                   ],
//                                 ),
//                               ),
//                               const Divider(height: 1),
//                               Expanded(
//                                 child: filtered.isEmpty
//                                     ? const Center(child: Text('No data'))
//                                     : ListView.builder(
//                                         itemCount: filtered.length,
//                                         itemBuilder: (_, i) {
//                                           final e = filtered[i];
//                                           return Container(
//                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                                             decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
//                                             child: Row(
//                                               children: [
//                                                 _BodyCell(e.title, width: 160),
//                                                 _BodyCell(e.fromDate.toIso8601String().split('T').first, width: 120),
//                                                 _BodyCell(e.toDate.toIso8601String().split('T').first, width: 120),
//                                                 _BodyCell(e.location, width: 150),
//                                                 SizedBox(
//                                                   width: 80,
//                                                   child: (e.imageUrl ?? '').isEmpty
//                                                       ? const SizedBox.shrink()
//                                                       : TextButton(
//                                                           onPressed: () => html.window.open(e.imageUrl!, '_blank'),
//                                                           child: const Text('View'),
//                                                         ),
//                                                 ),
//                                                 _BodyCell(e.description, width: 260),
//                                                 SizedBox(
//                                                   width: 60,
//                                                   child: IconButton(
//                                                     icon: const Icon(Icons.delete, color: Colors.red),
//                                                     onPressed: () => _delete(e.id),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _search() {
//     String q = '';
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Search Events'),
//         content: TextField(autofocus: true, onChanged: (v) => q = v, decoration: const InputDecoration(hintText: 'Event title'))),
//     ).then((_) {
//       setState(() {
//         filtered = eventsList.where((e) => e.title.toLowerCase().contains(q.toLowerCase())).toList();
//       });
//     });
//   }

//   void _downloadCsv() {
//     final b = StringBuffer()..writeln('Event Name,From Date,To Date,Location,Image,Description');
//     for (final e in filtered) {
//       b.writeln('${e.title},${e.fromDate.toIso8601String().split('T').first},'
//           '${e.toDate.toIso8601String().split('T').first},${e.location},'
//           '${(e.imageUrl ?? '').isNotEmpty ? 'Yes' : 'No'},${e.description.replaceAll(',', ' ')}');
//     }
//     final bytes = utf8.encode(b.toString());
//     final blob = html.Blob([bytes], 'text/csv');
//     final url = html.Url.createObjectUrlFromBlob(blob);
//     final a = html.AnchorElement(href: url)..setAttribute('download', 'event_updates.csv')..click();
//     html.Url.revokeObjectUrl(url);
//   }

//   Future<void> _delete(String id) async {
//     try {
//       final r = await http.delete(Uri.parse('$apiBase/events/$id'));
//       if (r.statusCode == 200) {
//         _toast('Deleted');
//         await _load();
//       } else {
//         _toast('Delete failed: ${r.statusCode}');
//       }
//     } catch (e) {
//       _toast('Delete error: $e');
//     }
//   }
// }

// class _HeaderCell extends StatelessWidget {
//   final String label; final double width;
//   const _HeaderCell(this.label, {required this.width});
//   @override Widget build(BuildContext context) =>
//       SizedBox(width: width, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)));
// }

// class _BodyCell extends StatelessWidget {
//   final String text; final double width;
//   const _BodyCell(this.text, {required this.width});
//   @override Widget build(BuildContext context) =>
//       SizedBox(width: width, child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1));
// }

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;// Web-only APIs (fine for Flutter Web builds)

import 'event_model_page.dart';
import 'add_event_page.dart';

// ====== CONFIG ======
const String apiBase = 'https://us-central1-servappbackend.cloudfunctions.net/api';
// Derive the origin (no /api) so we can resolve /uploads/...
final String _apiOrigin = apiBase.replaceFirst(RegExp(r'/api/?$'), '');

// ====== THEME ======
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class EventUpdatesPage extends StatefulWidget {
  const EventUpdatesPage({super.key});
  @override
  State<EventUpdatesPage> createState() => _EventUpdatesPageState();
}

class _EventUpdatesPageState extends State<EventUpdatesPage> {
  List<EventModel> _filtered = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- Networking ----------
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await http.get(Uri.parse('$apiBase/events'));
      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        eventsList = data.map((e) => EventModel.fromJson(e)).toList();
        setState(() => _filtered = List.of(eventsList));
      } else {
        _toast('Load failed: ${r.statusCode}');
      }
    } catch (e) {
      _toast('Load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final r = await http.delete(Uri.parse('$apiBase/events/$id'));
      if (r.statusCode == 200) {
        _toast('Deleted');
        await _load();
      } else {
        _toast('Delete failed: ${r.statusCode}');
      }
    } catch (e) {
      _toast('Delete error: $e');
    }
  }

  // ---------- Helpers ----------
  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // Turn '/uploads/abc.jpg' into 'http://localhost:3000/uploads/abc.jpg'
  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_apiOrigin$url';
    return '$_apiOrigin/$url';
  }

  // Show an in-app preview dialog for the image
  void _showImagePreview(String? url) {
    final link = _resolveUrl(url);
    if (link.isEmpty) {
      _toast('No image available');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            // Zoom/pan
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  link,
                  fit: BoxFit.contain,
                  // Progress indicator while loading
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 420,
                      width: 560,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  // Friendly error UI
                  errorBuilder: (ctx, err, stack) => SizedBox(
                    height: 420,
                    width: 560,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            link,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryBackgroundBottom,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Updates', style: TextStyle(color: kTextColor)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: kTextColor), onPressed: _search),
          IconButton(icon: const Icon(Icons.refresh, color: kTextColor), onPressed: _load),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadCsv,
                  style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventUploadPage()));
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kButtonColor, foregroundColor: kTextColor),
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 980,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                color: kPrimaryBackgroundBottom.withOpacity(0.5),
                                child: Row(
                                  children: const [
                                    _HeaderCell('Event Name', width: 160),
                                    _HeaderCell('From Date', width: 120),
                                    _HeaderCell('To Date', width: 120),
                                    _HeaderCell('Location', width: 150),
                                    _HeaderCell('Image', width: 100),
                                    _HeaderCell('Description', width: 260),
                                    _HeaderCell('Delete', width: 60),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: _filtered.isEmpty
                                    ? const Center(child: Text('No data'))
                                    : ListView.builder(
                                        itemCount: _filtered.length,
                                        itemBuilder: (_, i) {
                                          final e = _filtered[i];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                            ),
                                            child: Row(
                                              children: [
                                                _BodyCell(e.title, width: 160),
                                                _BodyCell(
                                                  e.fromDate.toIso8601String().split('T').first,
                                                  width: 120,
                                                ),
                                                _BodyCell(
                                                  e.toDate.toIso8601String().split('T').first,
                                                  width: 120,
                                                ),
                                                _BodyCell(e.location, width: 150),

                                                // ====== VIEW BUTTON (in-app preview) ======
                                                SizedBox(
                                                  width: 100,
                                                  child: (e.imageUrl ?? '').isEmpty
                                                      ? const Text('—', textAlign: TextAlign.center)
                                                      : TextButton(
                                                          onPressed: () => _showImagePreview(e.imageUrl),
                                                          child: const Text('View'),
                                                        ),
                                                ),

                                                _BodyCell(e.description, width: 260),
                                                SizedBox(
                                                  width: 60,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _delete(e.id),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search() {
    String q = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search Events'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => q = v,
          decoration: const InputDecoration(hintText: 'Event title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtered = eventsList.where((e) => e.title.toLowerCase().contains(q.toLowerCase())).toList();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _filtered = List.of(eventsList));
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _downloadCsv() {
    if (!kIsWeb) {
      _toast('CSV download is supported on Web only.');
      return;
    }

    final b = StringBuffer()
      ..writeln('Event Name,From Date,To Date,Location,Image,Description');

    for (final e in _filtered) {
      b.writeln('${e.title},'
          '${e.fromDate.toIso8601String().split('T').first},'
          '${e.toDate.toIso8601String().split('T').first},'
          '${e.location},'
          '${(e.imageUrl ?? '').isNotEmpty ? 'Yes' : 'No'},'
          '${e.description.replaceAll(',', ' ')}');
    }

    final bytes = utf8.encode(b.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)
      ..download = 'event_updates.csv'
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  const _HeaderCell(this.label, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final double width;
  const _BodyCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}
