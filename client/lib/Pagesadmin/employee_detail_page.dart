

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// // Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class EmployeeDetailPage extends StatelessWidget {
//   final Map<String, dynamic> employee;

//   const EmployeeDetailPage({super.key, required this.employee});

//   @override
//   Widget build(BuildContext context) {
//     LatLng checkInLocation = LatLng(
//       employee['latitude'],
//       employee['longitude'],
//     );
//     LatLng branchLocation = const LatLng(13.0300, 80.1800);

//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundTop,
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         foregroundColor: kTextColor,
//         title: Text("Employee ID: ${employee['id']}"),
//         actions: [
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: kPrimaryBackgroundTop,
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Center(
//               child: Text(
//                 employee['status'],
//                 style: const TextStyle(
//                   color: Colors.green,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 const SizedBox(height: 10),

//                 // Employee Details
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Table(
//                     defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                     columnWidths: const {
//                       0: FlexColumnWidth(1.5),
//                       1: FlexColumnWidth(2),
//                     },
//                     children: [
//                       _buildRow('Shift', employee['shift']),
//                       _buildRow('Location', employee['location']),
//                       _buildRow('Check-in', employee['checkIn']),
//                       _buildRow('Check-out', employee['checkOut']),
//                       _buildRow('Geofence', employee['geofence']),
//                       _buildRow('Latitude', employee['latitude'].toString()),
//                       _buildRow('Longitude', employee['longitude'].toString()),
//                       _buildRow('Status', employee['status'], statusColor: Colors.green),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // Map Legends
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     children: const [
//                       Icon(Icons.location_pin, color: Colors.purple),
//                       SizedBox(width: 1),
//                       Text("Checkin location"),
//                       SizedBox(width: 20),
//                       Icon(Icons.location_pin, color: Colors.red),
//                       SizedBox(width: 1),
//                       Text("Branch location"),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 // Map
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: checkInLocation,
//                           zoom: 12,
//                         ),
//                         markers: {
//                           Marker(
//                             markerId: const MarkerId('checkin'),
//                             position: checkInLocation,
//                             infoWindow: const InfoWindow(title: 'Check-in'),
//                           ),
//                           Marker(
//                             markerId: const MarkerId('branch'),
//                             position: branchLocation,
//                             infoWindow: const InfoWindow(title: 'Branch'),
//                             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//                           ),
//                         },
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Open Shift Log
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Open Shift Log",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       Text("Entry: ${employee['checkIn']}"),
//                       Text("Exit: ${employee['checkOut']}"),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   TableRow _buildRow(String label, String value, {Color? statusColor}) {
//     return TableRow(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Text(
//             label,
//             style: TextStyle(fontWeight: FontWeight.bold, color: kButtonColor),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Text(
//             value,
//             style: TextStyle(color: statusColor ?? Colors.black),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class EmployeeDetailPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    LatLng checkInLocation = LatLng(
      employee['latitude'],
      employee['longitude'],
    );
    LatLng branchLocation = const LatLng(13.0300, 80.1800);

    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        title: Text("Employee ID: ${employee['id']}"),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimaryBackgroundTop,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                employee['status'],
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Employee Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(1.5),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      _buildRow('Shift', employee['shift']),
                      _buildRow('Location', employee['location']),
                      _buildRow('Check-in', employee['checkIn']),
                      // _buildRow('Check-out', employee['checkOut']),
                      _buildRow('Geofence', employee['geofence']),
                      _buildRow('Latitude', employee['latitude'].toString()),
                      _buildRow('Longitude', employee['longitude'].toString()),
                      _buildRow('Status', employee['status'], statusColor: Colors.green),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Map Legends as Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.location_pin, size: 16, color: Colors.white),
                        label: const Text("Check-in", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.location_pin, size: 16, color: Colors.white),
                        label: const Text("Branch", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Map
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: checkInLocation,
                          zoom: 12,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('checkin'),
                            position: checkInLocation,
                            infoWindow: const InfoWindow(title: 'Check-in'),
                          ),
                          Marker(
                            markerId: const MarkerId('branch'),
                            position: branchLocation,
                            infoWindow: const InfoWindow(title: 'Branch'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Open Shift Log
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Open Shift Log",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Entry: ${employee['checkIn']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("Exit: ${employee['checkOut']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(String label, String value, {Color? statusColor}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: kButtonColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: TextStyle(color: statusColor ?? Colors.black),
          ),
        ),
      ],
    );
  }
}