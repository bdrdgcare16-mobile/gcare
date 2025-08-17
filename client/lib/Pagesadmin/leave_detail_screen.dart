// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import '../../constants.dart'; // Theme colors

// // Theme colors
// const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor             = Color(0xFF8C6EAF);
// const Color kButtonColor             = Color(0xFF655193);
// const Color kTextColor               = Colors.white;

// class RequestDetailsCard extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const RequestDetailsCard({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final double? latitude = double.tryParse(data['latitude']?.toString() ?? '');
//     final double? longitude = double.tryParse(data['longitude']?.toString() ?? '');
//     final bool showMap = latitude != null && longitude != null;

//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(50),
//         child: AppBar(
//           backgroundColor: kAppBarColor,
//           elevation: 1,
//           automaticallyImplyLeading: false,
//           title: Text(
//             "Employee ID: ${data['id'] ?? ''}",
//             style: TextStyle(fontSize: 16, color: kTextColor),
//           ),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: kTextColor),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.white, kPrimaryBackgroundBottom],
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildRow("Employee Name", data['name'] ?? '',
//                 "Requested Time", data['requestTime'] ?? ''),
//             _buildRow("Employee Reason", data['reason'] ?? '',
//                 "Rejection Remarks", data['rejectionRemarks'] ?? ''),
//             _buildRow("Request Date", data['requestDate'] ?? '',
//                 "Request Type", data['type'] ?? ''),
//             const SizedBox(height: 10),
//             const Text("Location Preview", style: TextStyle(fontWeight: FontWeight.bold)),
//             _buildRow("Request location", data['requestLocation'] ?? '',
//                 "Branch location", data['branchLocation'] ?? ''),
//             const SizedBox(height: 10),

//             if (showMap)
//               SizedBox(
//                 height: 250,
//                 child: GoogleMap(
//                   initialCameraPosition: CameraPosition(
//                     target: LatLng(latitude, longitude),
//                     zoom: 16,
//                   ),
//                   markers: {
//                     Marker(
//                       markerId: const MarkerId('requestLocation'),
//                       position: LatLng(latitude, longitude),
//                       infoWindow: const InfoWindow(title: 'Request Location'),
//                     ),
//                   },
//                 ),
//               )
//             else
//               const Text("📍 Location data not available"),

//             const Spacer(),

//             // Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 OutlinedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: OutlinedButton.styleFrom(
//                     side: BorderSide(color: kButtonColor),
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: Text("Cancel", style: TextStyle(color: kButtonColor)),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context, 'rejected');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text("Reject"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context, 'approved');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text("Approve"),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRow(
//       String leftLabel, String leftValue, String rightLabel, String rightValue) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(leftLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
//                 const SizedBox(height: 2),
//                 Text(leftValue, style: const TextStyle(color: Colors.black87)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(rightLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
//                 const SizedBox(height: 2),
//                 Text(rightValue, style: const TextStyle(color: Colors.black87)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class RequestDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const RequestDetailsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double? latitude = double.tryParse(data['latitude']?.toString() ?? '');
    final double? longitude = double.tryParse(data['longitude']?.toString() ?? '');
    final bool showMap = latitude != null && longitude != null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: kAppBarColor,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Text("Employee ID: ${data['id'] ?? data['empid'] ?? ''}", style: const TextStyle(fontSize: 16, color: kTextColor)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextColor), onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, kPrimaryBackgroundBottom],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _row("Employee Name", data['name'] ?? '', "Requested Time", data['requestTime'] ?? ''),
          _row("Employee Reason", data['reason'] ?? '', "Rejection Remarks", data['rejectionRemarks'] ?? ''),
          _row("Request Date", data['requestDate'] ?? '', "Request Type", data['type'] ?? ''),
          const SizedBox(height: 10),
          const Text("Location Preview", style: TextStyle(fontWeight: FontWeight.bold)),
          _row("Request location", data['requestLocation'] ?? '', "Branch location", data['branchLocation'] ?? ''),
          const SizedBox(height: 10),
          if (showMap)
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 16),
                markers: {Marker(markerId: const MarkerId('requestLocation'), position: LatLng(latitude, longitude))},
              ),
            )
          else
            const Text("📍 Location data not available"),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kButtonColor), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text("Cancel", style: TextStyle(color: kButtonColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'rejected'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text("Reject"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'approved'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text("Approve"),
            ),
          ])
        ]),
      ),
    );
  }

  Widget _row(String l1, String v1, String l2, String v2) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _col(l1, v1)),
          Expanded(child: _col(l2, v2)),
        ]),
      );
  Widget _col(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(color: Colors.black87)),
      ]);
}