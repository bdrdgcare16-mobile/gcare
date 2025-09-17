// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

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
//           title: Text("Employee ID: ${data['id'] ?? data['empid'] ?? ''}", style: const TextStyle(fontSize: 16, color: kTextColor)),
//           leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextColor), onPressed: () => Navigator.pop(context)),
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
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           _row("Employee Name", data['name'] ?? '', "Requested Time", data['requestTime'] ?? ''),
//           _row("Employee Reason", data['reason'] ?? '', "Rejection Remarks", data['rejectionRemarks'] ?? ''),
//           _row("Request Date", data['requestDate'] ?? '', "Request Type", data['type'] ?? ''),
//           const SizedBox(height: 10),
//           const Text("Location Preview", style: TextStyle(fontWeight: FontWeight.bold)),
//           _row("Request location", data['requestLocation'] ?? '', "Branch location", data['branchLocation'] ?? ''),
//           const SizedBox(height: 10),
//           if (showMap)
//             SizedBox(
//               height: 250,
//               child: GoogleMap(
//                 initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 16),
//                 markers: {Marker(markerId: const MarkerId('requestLocation'), position: LatLng(latitude, longitude))},
//               ),
//             )
//           else
//             const Text("📍 Location data not available"),
//           const Spacer(),
//           Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//             OutlinedButton(
//               onPressed: () => Navigator.pop(context),
//               style: OutlinedButton.styleFrom(side: const BorderSide(color: kButtonColor), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
//               child: const Text("Cancel", style: TextStyle(color: kButtonColor)),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, 'rejected'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
//               child: const Text("Reject"),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, 'approved'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
//               child: const Text("Approve"),
//             ),
//           ])
//         ]),
//       ),
//     );
//   }

//   Widget _row(String l1, String v1, String l2, String v2) => Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Expanded(child: _col(l1, v1)),
//           Expanded(child: _col(l2, v2)),
//         ]),
//       );
//   Widget _col(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(l, style: const TextStyle(fontWeight: FontWeight.w500)),
//         const SizedBox(height: 2),
//         Text(v, style: const TextStyle(color: Colors.black87)),
//       ]);
// }
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class RequestDetailsCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const RequestDetailsCard({super.key, required this.data});

  @override
  State<RequestDetailsCard> createState() => _RequestDetailsCardState();
}

class _RequestDetailsCardState extends State<RequestDetailsCard> {
  Position? _currentPos;
  bool _fetchingLoc = false;
  String? _locError;

  // ---- Robust pickers to tolerate different keys from attendance/leaves ----
  double? _pickNum(List<String> keys) {
    for (final k in keys) {
      final v = widget.data[k];
      if (v == null) continue;
      final d = double.tryParse(v.toString());
      if (d != null) return d;
    }
    return null;
  }

  String _pickStr(List<String> keys) {
    for (final k in keys) {
      final v = widget.data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    // If the request has no coordinates, try to get device location as a fallback.
    final lat = _pickNum(['latitude','lat','checkInLatitude','checkOutLatitude','expectedLatitude']);
    final lng = _pickNum(['longitude','lng','checkInLongitude','checkOutLongitude','expectedLongitude']);
    if (lat == null || lng == null) {
      _ensureDeviceLocation();
    }
  }

  Future<void> _ensureDeviceLocation() async {
    setState(() {
      _fetchingLoc = true;
      _locError = null;
    });

    try {
      // 1) Check service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locError = 'Location services are disabled.';
        });
        return;
      }

      // 2) Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locError = 'Location permission denied.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locError = 'Location permission permanently denied.';
        });
        return;
      }

      // 3) Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPos = pos;
      });
    } catch (e) {
      setState(() {
        _locError = 'Failed to get location: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLoc = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // IDs & names
    final empId = _pickStr(['empid', 'id', 'employeeId']);
    final name  = _pickStr(['name', 'employeeName']);

    // Timestamps
    final requestTime = _pickStr(['requestTime', 'createdAt', 'updatedAt']);
    final requestDate = _pickStr(['requestDate', 'date']);

    // Reason & remarks
    final reason = _pickStr(['reason', 'note', 'remarks']);
    final rejectionRemarks = _pickStr(['rejectionRemarks']);

    // Attendance / location fields
    final otherLocation = _pickStr(['otherLocation', 'requestLocation']);
    final branchLocation = _pickStr(['branchLocation', 'location']); // e.g., "Pudur"
    final withinRadius = _pickStr(['withinRadius']);
    final distanceFromBranch = _pickStr(['distanceFromBranch']);

    // Latitude / Longitude from any known keys (request-provided)
    final reqLat  = _pickNum(['latitude','lat','checkInLatitude','checkOutLatitude','expectedLatitude']);
    final reqLng  = _pickNum(['longitude','lng','checkInLongitude','checkOutLongitude','expectedLongitude']);

    // Map decision logic:
    // - If request has coordinates -> use them.
    // - Else if device location available -> use current position.
    final bool hasReqCoords = (reqLat != null && reqLng != null);
    final bool hasDeviceCoords = _currentPos != null;
    final bool showMap = hasReqCoords || hasDeviceCoords;

    final LatLng? target = hasReqCoords
        ? LatLng(reqLat, reqLng)
        : (hasDeviceCoords ? LatLng(_currentPos!.latitude, _currentPos!.longitude) : null);

    // Build markers
    final Set<Marker> markers = {};
    if (hasReqCoords) {
      markers.add(Marker(
        markerId: const MarkerId('requestLocation'),
        position: LatLng(reqLat, reqLng),
        infoWindow: const InfoWindow(title: 'Request Location'),
      ));
    } else if (hasDeviceCoords) {
      markers.add(Marker(
        markerId: const MarkerId('yourLocation'),
        position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: kAppBarColor,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Text("Employee ID: $empId", style: const TextStyle(fontSize: 16, color: kTextColor)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextColor), onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 🧱 All your existing rows/fields (unchanged)
          _row("Employee Name", name, "Request Type", _pickStr(['type','category'])),
          _row("Requested Time", requestTime, "Request Date", requestDate),
          _row("Employee Reason", reason, "Rejection Remarks", rejectionRemarks),
          const SizedBox(height: 10),
          const Text("Location Preview", style: TextStyle(fontWeight: FontWeight.bold)),
          _row("Request location", otherLocation, "Branch location", branchLocation),
          _row("Within radius", withinRadius, "Distance from branch (m)", distanceFromBranch),
          const SizedBox(height: 10),

          // 🗺️ Map (request or device location) OR status text with retry
          if (showMap && target != null)
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: target, zoom: 16),
                markers: markers,
                myLocationEnabled: hasDeviceCoords,       // show blue dot if device location used
                myLocationButtonEnabled: hasDeviceCoords, // show button if device location used
                zoomControlsEnabled: false,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locError ??
                      (_fetchingLoc
                          ? "Fetching device location…"
                          : "📍 Location data not available"),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                if (!_fetchingLoc)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _ensureDeviceLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text("Use my location"),
                        style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
                      ),
                      const SizedBox(width: 10),
                      if (_locError != null)
                        OutlinedButton(
                          onPressed: () => Geolocator.openAppSettings(),
                          child: const Text("Open Settings"),
                        ),
                    ],
                  ),
              ],
            ),

          const Spacer(),

          // ⛳ Action buttons (unchanged)
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

  Widget _col(String l, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(v.isEmpty ? '-' : v, style: const TextStyle(color: Colors.black87)),
        ],
      );
}

  