// // // // import 'package:flutter/material.dart';

// // // // class LeaveCard extends StatelessWidget {
// // // //   final Map<String, dynamic> item;
// // // //   final Function(String) onStatusChange;

// // // //   const LeaveCard({
// // // //     super.key,
// // // //     required this.item,
// // // //     required this.onStatusChange,
// // // //   });

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Card(
// // // //       color: Colors.deepPurple[100],
// // // //       child: Padding(
// // // //         padding: const EdgeInsets.all(10),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             ...item.entries
// // // //                 .where((e) => e.key != 'status') // Skip status from list
// // // //                 .map((e) => Text('${e.key} : ${e.value}')),
// // // //             const SizedBox(height: 10),
// // // //             if (item['status'] == 'pending')
// // // //               Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.end,
// // // //                 children: [
// // // //                   ElevatedButton(
// // // //                     onPressed: () => onStatusChange('approved'),
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: Colors.green,
// // // //                       minimumSize: const Size(60, 30), // Button size reduced
// // // //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // // //                       textStyle: const TextStyle(fontSize: 12),
// // // //                     ),
// // // //                     child: const Text('Approve'),
// // // //                   ),
// // // //                   const SizedBox(width: 8),
// // // //                   ElevatedButton(
// // // //                     onPressed: () => onStatusChange('rejected'),
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: Colors.red,
// // // //                       minimumSize: const Size(60, 30), // Button size reduced
// // // //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // // //                       textStyle: const TextStyle(fontSize: 12),
// // // //                     ),
// // // //                     child: const Text('Reject'),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             if (item['status'] != 'pending')
// // // //               Text("Status: ${item['status'].toUpperCase()}"),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // import 'package:flutter/material.dart';
// // import 'leave_detail_screen.dart'; // 👈 Detail screen import

// // class LeaveCard extends StatelessWidget {
// //   final Map<String, dynamic> item;
// //   final Function(String) onStatusChange;

// //   const LeaveCard({
// //     super.key,
// //     required this.item,
// //     required this.onStatusChange,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () async {
// //         final type = item['type']?.toString().toLowerCase();
// //         if (type == 'late check in' || type == 'late check out') {
// //           final result = await Navigator.push(
// //             context,
// //             MaterialPageRoute(
// //               builder: (_) => RequestDetailsCard(data: item),
// //             ),
// //           );

// //           if (result == 'approved' || result == 'rejected') {
// //             onStatusChange(result);
// //           }
// //         }
// //       },
// //       child: Card(
// //         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
// //         elevation: 3,
// //         color: Colors.white,
// //         child: Padding(
// //           padding: const EdgeInsets.all(14),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               ...item.entries.where((e) => e.key != 'status').map((e) {
// //                 final key = _formatKey(e.key);
// //                 String value = e.value?.toString() ?? '';

// //                 // ✅ Show default if "reason" is empty
// //                 if (e.key == 'reason' && value.trim().isEmpty) {
// //                   value = 'Other location';
// //                 }

// //                 return Padding(
// //                   padding: const EdgeInsets.symmetric(vertical: 2),
// //                   child: Text("$key: $value"),
// //                 );
// //               }),

// //               const SizedBox(height: 10),

// //               if (item['status']?.toLowerCase() == 'pending')
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.end,
// //                   children: [
// //                     ElevatedButton(
// //                       onPressed: () => onStatusChange('approved'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.green,
// //                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                         minimumSize: const Size(0, 30),
// //                         textStyle: const TextStyle(fontSize: 12),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(20),
// //                         ),
// //                       ),
// //                       child: const Text("Approve"),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     ElevatedButton(
// //                       onPressed: () => onStatusChange('rejected'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.red,
// //                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                         minimumSize: const Size(0, 30),
// //                         textStyle: const TextStyle(fontSize: 12),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(20),
// //                         ),
// //                       ),
// //                       child: const Text("Reject"),
// //                     ),
// //                   ],
// //                 )
// //               else
// //                 Text(
// //                   "Status: ${item['status'].toString().capitalize()}",
// //                   style: TextStyle(
// //                     color: item['status'] == 'approved'
// //                         ? Colors.green
// //                         : item['status'] == 'rejected'
// //                             ? Colors.red
// //                             : Colors.black,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatKey(String key) {
// //     return key
// //         .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
// //         .capitalize();
// //   }
// // }

// // extension StringExtension on String {
// //   String capitalize() {
// //     if (isEmpty) return this;
// //     return this[0].toUpperCase() + substring(1);
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'leave_detail_screen.dart';

// class LeaveCard extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final Function(String) onStatusChange;

//   const LeaveCard({
//     super.key,
//     required this.item,
//     required this.onStatusChange,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () async {
//         final type = item['type']?.toString().toLowerCase();
//         if (type == 'late check in' || type == 'early check out') {
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => RequestDetailsCard(data: item)),
//           );
//           if (result == 'approved' || result == 'rejected') {
//             onStatusChange(result);
//           }
//         }
//       },
//       child: Card(
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//         elevation: 3,
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ...item.entries.where((e) => e.key != 'status').map((e) {
//                 final key = _formatKey(e.key);
//                 String value = e.value?.toString() ?? '';
//                 if (e.key == 'reason' && value.trim().isEmpty) {
//                   value = 'Other location';
//                 }
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 2),
//                   child: Text("$key: $value"),
//                 );
//               }),
//               const SizedBox(height: 10),
//               if ((item['status'] ?? '').toString().toLowerCase() == 'pending')
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () => onStatusChange('approved'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         minimumSize: const Size(0, 30),
//                         textStyle: const TextStyle(fontSize: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text("Approve"),
//                     ),
//                     const SizedBox(width: 10),
//                     ElevatedButton(
//                       onPressed: () => onStatusChange('rejected'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         minimumSize: const Size(0, 30),
//                         textStyle: const TextStyle(fontSize: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text("Reject"),
//                     ),
//                   ],
//                 )
//               else
//                 Text(
//                   "Status: ${_cap((item['status'] ?? '').toString())}",
//                   style: TextStyle(
//                     color: (item['status'] == 'approved')
//                         ? Colors.green
//                         : (item['status'] == 'rejected')
//                         ? Colors.red
//                         : Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatKey(String key) => key
//       .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
//       .split('_')
//       .map(_cap)
//       .join(' ');
//   String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
// }
import 'package:flutter/material.dart';
import 'leave_detail_screen.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(String) onStatusChange;

  const LeaveCard({
    super.key,
    required this.item,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final type = item['type']?.toString().toLowerCase();
        if (type == 'late check in' || type == 'early check out') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RequestDetailsCard(data: item)),
          );
          if (result == 'approved' || result == 'rejected') {
            onStatusChange(result);
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 3,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...item.entries.where((e) => e.key != 'status').map((e) {
                final key = _formatKey(e.key);
                String value = e.value?.toString() ?? '';
                if (e.key == 'reason' && value.trim().isEmpty) {
                  value = '—'; // nicer empty reason
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text("$key: $value"),
                );
              }),
              const SizedBox(height: 10),
              if ((item['status'] ?? '').toString().toLowerCase() == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => onStatusChange('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Approve"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => onStatusChange('rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Reject"),
                    ),
                  ],
                )
              else
                Text(
                  "Status: ${_cap((item['status'] ?? '').toString())}",
                  style: TextStyle(
                    color: (item['status'] == 'approved')
                        ? Colors.green
                        : (item['status'] == 'rejected')
                            ? Colors.red
                            : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatKey(String key) => key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split('_')
      .map(_cap)
      .join(' ');
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
