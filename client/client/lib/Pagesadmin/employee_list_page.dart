// import 'package:flutter/material.dart';
// import 'employee_detail_page.dart'; // Import your detail page here

// class EmployeeListPage extends StatefulWidget {
//   const EmployeeListPage({super.key});

//   @override
//   State<EmployeeListPage> createState() => _EmployeeListPageState();
// }

// class _EmployeeListPageState extends State<EmployeeListPage> {
//   List<Map<String, dynamic>> employeeData = [
//     {
//       'name': 'Sundar',
//       'id': 'EMP001',
//       'date': '27 Jun 2025',
//       'checkIn': '09:10 AM',
//       'checkOut': '06:00 PM',
//       'department': 'HR',
//       'shift': 'Morning',
//       'location': 'Chennai',
//       'latitude': 13.047788999,
//       'longitude': 80.090998,
//       'status': 'Present',
//       'geofence': '-',
//     },
//     {
//       'name': 'Kumar',
//       'id': 'EMP002',
//       'date': '27 Jun 2025',
//       'checkIn': '09:30 AM',
//       'checkOut': '06:10 PM',
//       'department': 'Finance',
//       'shift': 'Morning',
//       'location': 'Madurai',
//       'latitude': 13.03,
//       'longitude': 80.18,
//       'status': 'Present',
//       'geofence': '-',
//     },
//     {
//       'name': 'Priya',
//       'id': 'EMP003',
//       'date': '27 Jun 2025',
//       'checkIn': '10:00 AM',
//       'checkOut': '07:00 PM',
//       'department': 'IT',
//       'shift': 'Evening',
//       'location': 'Trichy',
//       'latitude': 10.7905,
//       'longitude': 78.7047,
//       'status': 'Present',
//       'geofence': '-',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Employee List'),
//         backgroundColor: const Color(0xFF00796B),
//       ),
//       body: Padding(
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
//         elevation: 3,
//         margin: const EdgeInsets.symmetric(vertical: 8),
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
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text("ID: ${emp['id']} | Date: ${emp['date']}"),
//               Text(
//                 "Check-in: ${emp['checkIn']} | Check-out: ${emp['checkOut']}",
//               ),
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


import 'package:flutter/material.dart';
import 'employee_detail_page.dart'; // Import your detail page

// App Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  List<Map<String, dynamic>> employeeData = [
    {
      'name': 'Sundar',
      'id': 'EMP001',
      'date': '27 Jun 2025',
      'checkIn': '09:10 AM',
      // 'checkOut': '06:00 PM',
      'department': 'HR',
      'shift': 'Morning',
      'location': 'Chennai',
      'latitude': 13.047788999,
      'longitude': 80.090998,
      'status': 'Present',
      'geofence': '-',
    },
    {
      'name': 'Kumar',
      'id': 'EMP002',
      'date': '27 Jun 2025',
      'checkIn': '09:30 AM',
      // 'checkOut': '06:10 PM',
      'department': 'Finance',
      'shift': 'Morning',
      'location': 'Madurai',
      'latitude': 13.03,
      'longitude': 80.18,
      'status': 'Present',
      'geofence': '-',
    },
    {
      'name': 'Priya',
      'id': 'EMP003',
      'date': '27 Jun 2025',
      'checkIn': '10:00 AM',
      // 'checkOut': '07:00 PM',
      'department': 'IT',
      'shift': 'Evening',
      'location': 'Trichy',
      'latitude': 10.7905,
      'longitude': 78.7047,
      'status': 'Present',
      'geofence': '-',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: employeeData.isNotEmpty
            ? ListView.builder(
                itemCount: employeeData.length,
                itemBuilder: (context, index) {
                  final emp = employeeData[index];
                  return EmployeeCard(emp: emp);
                },
              )
            : const Center(
                child: Text(
                  "No Employee Data Found!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> emp;

  const EmployeeCard({super.key, required this.emp});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmployeeDetailPage(employee: emp)),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emp['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kButtonColor,
                ),
              ),
              const SizedBox(height: 4),
              Text("ID: ${emp['id']} | Date: ${emp['date']}"),
              Text("Check-in: ${emp['checkIn']}"),
              const Divider(),
              Text("Department: ${emp['department']}"),
              Text("Shift: ${emp['shift']}"),
              Text("Location: ${emp['location']}"),
            ],
          ),
        ),
      ),
    );
  }
}
