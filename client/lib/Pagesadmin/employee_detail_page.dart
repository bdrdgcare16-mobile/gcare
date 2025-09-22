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
//     // Safe numeric casting (prevents type issues)
//     final double lat = (employee['latitude'] as num).toDouble();
//     final double lng = (employee['longitude'] as num).toDouble();

//     final LatLng checkInLocation = LatLng(lat, lng);
//     final LatLng branchLocation = const LatLng(13.0300, 80.1800);

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
//                 employee['status'] ?? '',
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
//             padding: const EdgeInsets.only(bottom: 20),
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
//                       _buildRow('Shift', employee['shift'] ?? '-'),
//                       _buildRow('Location', employee['location'] ?? '-'),
//                       _buildRow('Check-in', employee['checkIn'] ?? '-'),
//                       // _buildRow('Check-out', employee['checkOut']),
//                       _buildRow('Geofence', employee['geofence'] ?? '-'),
//                       _buildRow('Latitude', lat.toString()),
//                       _buildRow('Longitude', lng.toString()),
//                       _buildRow('Status', employee['status'] ?? '-', statusColor: Colors.green),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Map Legends as Buttons
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.location_pin, size: 16, color: Colors.white),
//                         label: const Text("Check-in", style: TextStyle(fontSize: 12)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.purple,
//                           minimumSize: const Size(100, 36),
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.location_pin, size: 16, color: Colors.white),
//                         label: const Text("Branch", style: TextStyle(fontSize: 12)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           minimumSize: const Size(100, 36),
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 12),

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
//                             icon: BitmapDescriptor.defaultMarkerWithHue(
//                               BitmapDescriptor.hueRed,
//                             ),
//                           ),
//                         },
//                         myLocationButtonEnabled: false,
//                         zoomControlsEnabled: false,
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
//                       Text("Entry: ${employee['checkIn'] ?? '-'}",
//                           style: const TextStyle(fontWeight: FontWeight.w500)),
//                       Text("Exit: ${employee['checkOut'] ?? '-'}",
//                           style: const TextStyle(fontWeight: FontWeight.w500)),
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
//             style: const TextStyle(fontWeight: FontWeight.bold, color: kButtonColor),
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

// Keep these in sync with your app theme
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class EmployeeDetailPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailPage({super.key, required this.employee});

  String _str(dynamic v, {String fallback = '-'}) {
    if (v == null) return fallback;
    if (v is String && v.trim().isEmpty) return fallback;
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final id = _str(employee['id']);
    final status = _str(employee['status'], fallback: '—');
    final name = _str(employee['name'], fallback: 'Employee');

    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        title: Text('Employee ID: $id'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _StatusChip(status: status),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kButtonColor,
              ),
            ),
            const SizedBox(height: 12),

            // Details grid
            _DetailRow(label: 'Shift', value: _str(employee['shift'])),
            _DetailRow(label: 'Location', value: _str(employee['location'])),
            _DetailRow(label: 'Check-in', value: _str(employee['checkIn'])),
            _DetailRow(label: 'Check-out', value: _str(employee['checkOut'], fallback: '—')),
            _DetailRow(label: 'Geofence', value: _str(employee['geofence'])),
            _DetailRow(label: 'Latitude', value: _str(employee['latitude'])),
            _DetailRow(label: 'Longitude', value: _str(employee['longitude'])),
            _DetailRow(label: 'Status', value: status),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Hook up your check-in flow
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Check-in tapped')),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Check in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Hook up your branch/location action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Branch tapped')),
                      );
                    },
                    icon: const Icon(Icons.place),
                    label: const Text('Branch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Map Placeholder (replaces the widget that caused the error)
            _MapPlaceholder(
              latitudeText: _str(employee['latitude']),
              longitudeText: _str(employee['longitude']),
              location: _str(employee['location']),
            ),

            const SizedBox(height: 16),

            // Shift log (example using available values)
            const Text(
              'Open Shift Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _ShiftLogRow(
              entryLabel: 'Entry',
              entryValue: _str(employee['checkIn']),
              exitLabel: 'Exit',
              exitValue: _str(employee['checkOut'], fallback: 'null'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftLogRow extends StatelessWidget {
  final String entryLabel;
  final String entryValue;
  final String exitLabel;
  final String exitValue;

  const _ShiftLogRow({
    required this.entryLabel,
    required this.entryValue,
    required this.exitLabel,
    required this.exitValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text('$entryLabel: $entryValue')),
          Expanded(child: Text('$exitLabel: $exitValue', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bgFor(String s) {
    final v = s.toLowerCase();
    if (v.contains('present')) return Colors.green.shade600;
    if (v.contains('absent')) return Colors.red.shade600;
    if (v.contains('leave')) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bgFor(status),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String latitudeText;
  final String longitudeText;
  final String location;

  const _MapPlaceholder({
    required this.latitudeText,
    required this.longitudeText,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Simple icon/thumbnail area
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: const Icon(Icons.map, size: 28, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Preview (Placeholder)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Location: $location'),
                Text('Latitude: $latitudeText'),
                Text('Longitude: $longitudeText'),
                const Spacer(),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Optional: Open external map app with lat/lng
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Open map (not implemented)')),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kButtonColor,
                        side: const BorderSide(color: kButtonColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Replace with real map when ready',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
