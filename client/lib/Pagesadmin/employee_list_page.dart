// import 'package:flutter/material.dart';
// import 'employee_detail_page.dart'; // Import your detail page

// // App Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class EmployeeListPage extends StatefulWidget {
//   const EmployeeListPage({super.key});

//   @override
//   State<EmployeeListPage> createState() => _EmployeeListPageState();
// }

// class _EmployeeListPageState extends State<EmployeeListPage> {
//   // Empty list, will be filled dynamically later
//   List<Map<String, dynamic>> employeeData = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundTop,
//       appBar: AppBar(
//         title: const Text('Employee List'),
//         backgroundColor: kAppBarColor,
//         foregroundColor: kTextColor,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         padding: const EdgeInsets.all(16.0),
//         child: employeeData.isNotEmpty
//             ? ListView.builder(
//                 itemCount: employeeData.length,
//                 itemBuilder: (context, index) {
//                   final emp = employeeData[index];
//                   return EmployeeCard(emp: emp);
//                 },
//               )
//             : const Center(
//                 child: Text(
//                   "No Employee Data Found!",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               ),
//       ),
//     );
//   }
// }

// class EmployeeCard extends StatelessWidget {
//   final Map<String, dynamic> emp;

//   const EmployeeCard({super.key, required this.emp});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => EmployeeDetailPage(employee: emp)),
//         );
//       },
//       child: Card(
//         elevation: 4,
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         color: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 emp['name'] ?? '',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: kButtonColor,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text("ID: ${emp['id']} | Date: ${emp['date']}"),
//               Text("Check-in: ${emp['checkIn']}"),
//               const Divider(),
//               Text("Department: ${emp['department']}"),
//               Text("Shift: ${emp['shift']}"),
//               Text("Location: ${emp['location']}"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
