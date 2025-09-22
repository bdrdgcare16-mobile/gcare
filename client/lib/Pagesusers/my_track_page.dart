// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// // ✅ auth holder
// import 'package:serv_app/models/company_data.dart';

// import '../services/tracking_service.dart';

// // Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class MyTrackPage extends StatefulWidget {
//   const MyTrackPage({super.key});
//   @override
//   State<MyTrackPage> createState() => _MyTrackPageState();
// }

// class _MyTrackPageState extends State<MyTrackPage> {
//   DateTime? selectedDate;
//   String? selectedShift;
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController dateController = TextEditingController();

//   final List<String> shiftOptions = ['Shift 1', 'Shift 2', 'Shift 3'];

//   TrackingService? _tracker;

//   final String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app';
//   String? _jwt;
//   String? _empId;

//   GoogleMapController? _mapCtrl;
//   MapType _mapType = MapType.normal;
//   Set<Polyline> _polylines = {};
//   Set<Marker> _markers = {};
//   Set<Circle> _circles = {};
//   LatLng? _center;

//   @override
//   void initState() {
//     super.initState();

//     _jwt = CompanyData.token;
//     _empId = CompanyData.empid;

//     if ((_jwt ?? '').isNotEmpty) {
//       _tracker = TrackingService(apiBase: _apiBase, jwtToken: _jwt!, empId: _empId ?? '');
//     }

//     final now = DateTime.now();
//     selectedDate = now;
//     dateController.text =
//         "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
//     _loadAndDrawPath();
//   }

//   Future<void> startTrackingGlue() async {
//     if (_tracker == null) return;
//     await _tracker!.startAfterCheckIn();
//   }

//   Future<void> stopTrackingGlue() async {
//     if (_tracker == null) return;
//     await _tracker!.stopAfterCheckOut();
//   }

//   String _dateIsoFromPicker() {
//     final d = selectedDate ?? DateTime.now();
//     return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
//   }

//   Future<void> _loadAndDrawPath() async {
//     try {
//       if ((_jwt ?? '').isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You are not logged in. Please sign in again.')),
//         );
//         return;
//       }

//       final dateIso = _dateIsoFromPicker();
//       final uri = Uri.parse('$_apiBase/api/tracking/day')
//           .replace(queryParameters: {'dateIso': dateIso});

//       final res = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $_jwt',
//           // 👇 ensure backend knows which employee if JWT has no empid claim
//           if ((_empId ?? '').isNotEmpty) 'x-empid': _empId!,
//         },
//       );

//       if (res.statusCode == 401 || res.statusCode == 403) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load path: ${jsonDecode(res.body)['message'] ?? res.statusCode}')),
//         );
//         return;
//       }
//       if (res.statusCode >= 400) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load path: ${res.statusCode}')),
//         );
//         return;
//       }

//       final body = json.decode(res.body) as Map<String, dynamic>;
//       final data = body['data'];
//       if (data == null || data['pathMap'] == null || (data['pathMap'] as List).isEmpty) {
//         setState(() {
//           _polylines = {};
//           _markers = {};
//           _circles = {};
//           _center ??= const LatLng(12.9716, 77.5946);
//         });
//         return;
//       }

//       final List<dynamic> pts = data['pathMap'];
//       final List<LatLng> latLngs = pts
//           .map((e) => LatLng(
//                 (e['lat'] as num).toDouble(),
//                 (e['lng'] as num).toDouble(),
//               ))
//           .toList();

//       final start = latLngs.first;
//       final end = latLngs.last;

//       final polyline = Polyline(
//         polylineId: const PolylineId('route'),
//         points: latLngs,
//         width: 5,
//       );

//       final circles = <Circle>{
//         for (int i = 0; i < latLngs.length; i++)
//           Circle(
//             circleId: CircleId('p$i'),
//             center: latLngs[i],
//             radius: 0.5,
//             strokeWidth: 0,
//             fillColor: Colors.deepPurpleAccent.withOpacity(0.85),
//           )
//       };

//       final startMarker = Marker(
//         markerId: const MarkerId('start'),
//         position: start,
//         infoWindow: const InfoWindow(title: 'Start'),
//       );

//       final endMarker = Marker(
//         markerId: const MarkerId('end'),
//         position: end,
//         infoWindow: const InfoWindow(title: 'End'),
//       );

//       setState(() {
//         _polylines = {polyline};
//         _markers = {startMarker, endMarker};
//         _circles = circles;
//         _center = end;
//       });

//       if (_mapCtrl != null && latLngs.isNotEmpty) {
//         await _mapCtrl!.animateCamera(
//           CameraUpdate.newLatLngBounds(_boundsFromLatLngs(latLngs), 48),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading path: $e')),
//       );
//     }
//   }

//   LatLngBounds _boundsFromLatLngs(List<LatLng> list) {
//     double? minLat, maxLat, minLng, maxLng;
//     for (final p in list) {
//       minLat = (minLat == null) ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
//       maxLat = (maxLat == null) ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
//       minLng = (minLng == null) ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
//       maxLng = (maxLng == null) ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
//     }
//     return LatLngBounds(
//       southwest: LatLng(minLat ?? 0, minLng ?? 0),
//       northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
//     );
//   }

//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null) {
//       setState(() {
//         selectedDate = picked;
//         dateController.text =
//             "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       });
//       _loadAndDrawPath();
//     }
//   }

//   void _submit() {
//     if (selectedDate == null || selectedShift == null || descriptionController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please complete all fields')),
//       );
//       return;
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Track submitted successfully!')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: Center(
//           child: Container(
//             margin: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: kPrimaryBackgroundTop,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 6,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: kAppBarColor,
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//                     ),
//                     child: Row(
//                       children: [
//                         GestureDetector(
//                           onTap: () => Navigator.pop(context),
//                           child: const Icon(Icons.arrow_back, color: kTextColor),
//                         ),
//                         const SizedBox(width: 10),
//                         const Text('My Track',
//                             style: TextStyle(
//                               color: kTextColor,
//                               fontWeight: FontWeight.bold,
//                             )),
//                       ],
//                     ),
//                   ),

//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextFormField(
//                           controller: dateController,
//                           readOnly: true,
//                           onTap: _pickDate,
//                           decoration: InputDecoration(
//                             labelText: "Choose date",
//                             prefixIcon: const Icon(Icons.calendar_today, color: kButtonColor),
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: kButtonColor, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 15),
//                         DropdownButtonFormField<String>(
//                           decoration: InputDecoration(
//                             labelText: "Select shift",
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: kButtonColor, width: 2),
//                             ),
//                           ),
//                           initialValue: selectedShift,
//                           items: shiftOptions.map((shift) {
//                             return DropdownMenuItem(
//                               value: shift,
//                               child: Text(shift),
//                             );
//                           }).toList(),
//                           onChanged: (value) => setState(() => selectedShift = value),
//                         ),
//                         const SizedBox(height: 15),
//                         TextFormField(
//                           controller: descriptionController,
//                           maxLines: 2,
//                           decoration: InputDecoration(
//                             labelText: "Description",
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: kButtonColor, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         const Text("Map"),
//                         const SizedBox(height: 10),
//                         Row(
//                           children: [
//                             ChoiceChip(
//                               label: const Text('Map'),
//                               selected: _mapType == MapType.normal,
//                               onSelected: (_) => setState(() => _mapType = MapType.normal),
//                             ),
//                             const SizedBox(width: 8),
//                             ChoiceChip(
//                               label: const Text('Satellite'),
//                               selected: _mapType == MapType.satellite,
//                               onSelected: (_) => setState(() => _mapType = MapType.satellite),
//                             ),
//                             const Spacer(),
//                             IconButton(
//                               icon: const Icon(Icons.refresh),
//                               tooltip: 'Reload path',
//                               onPressed: _loadAndDrawPath,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),

//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: SizedBox(
//                             height: 260,
//                             width: double.infinity,
//                             child: GoogleMap(
//                               initialCameraPosition: CameraPosition(
//                                 target: _center ?? const LatLng(12.9716, 77.5946),
//                                 zoom: 16,
//                               ),
//                               onMapCreated: (c) {
//                                 _mapCtrl = c;
//                                 if (_polylines.isNotEmpty) {
//                                   final pts = _polylines.first.points;
//                                   if (pts.isNotEmpty) {
//                                     _mapCtrl!.moveCamera(
//                                       CameraUpdate.newLatLngBounds(_boundsFromLatLngs(pts), 48),
//                                     );
//                                   }
//                                 }
//                               },
//                               mapType: _mapType,
//                               polylines: _polylines,
//                               markers: _markers,
//                               circles: _circles,
//                               myLocationButtonEnabled: false,
//                               zoomControlsEnabled: true,
//                               compassEnabled: false,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 25),
//                         ElevatedButton(
//                           onPressed: _submit,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: kButtonColor,
//                             minimumSize: const Size(double.infinity, 45),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                           ),
//                           child: const Text("Submit", style: TextStyle(color: kTextColor)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ✅ auth holder
import 'package:serv_app/models/company_data.dart';

import '../services/tracking_service.dart';

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class MyTrackPage extends StatefulWidget {
  const MyTrackPage({super.key});
  @override
  State<MyTrackPage> createState() => _MyTrackPageState();
}

class _MyTrackPageState extends State<MyTrackPage> {
  DateTime? selectedDate;
  String? selectedShift; // read-only, fetched from profile
  final TextEditingController dateController = TextEditingController();

  TrackingService? _tracker;

  final String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app';
  String? _jwt;
  String? _empId;

  GoogleMapController? _mapCtrl;
  MapType _mapType = MapType.normal;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _center;

  @override
  void initState() {
    super.initState();

    _jwt = CompanyData.token;
    _empId = CompanyData.empid;

    if ((_jwt ?? '').isNotEmpty) {
      _tracker = TrackingService(apiBase: _apiBase, jwtToken: _jwt!, empId: _empId ?? '');
    }

    final now = DateTime.now();
    selectedDate = now;
    dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    _loadShiftFromProfile(); // same shift that Attendance shows
    _loadAndDrawPath();
  }

  Future<void> _loadShiftFromProfile() async {
    try {
      if ((_jwt ?? '').isEmpty) return;
      final uri = Uri.parse('$_apiBase/api/auth/me');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $_jwt'});
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final profile = (body['employeeProfile'] is Map<String, dynamic>)
          ? body['employeeProfile'] as Map<String, dynamic>
          : <String, dynamic>{};
      final shift = (profile['shiftGroup'] ?? body['shiftGroup'] ?? '').toString();
      if (!mounted) return;
      setState(() => selectedShift = shift.isEmpty ? 'Shift' : shift);
    } catch (_) {}
  }

  Future<void> startTrackingGlue() async {
    if (_tracker == null) return;
    await _tracker!.startAfterCheckIn();
  }

  Future<void> stopTrackingGlue() async {
    if (_tracker == null) return;
    await _tracker!.stopAfterCheckOut();
  }

  String _dateIsoFromPicker() {
    final d = selectedDate ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAndDrawPath() async {
    try {
      if ((_jwt ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please sign in again.')),
        );
        return;
      }

      final dateIso = _dateIsoFromPicker();
      final uri = Uri.parse('$_apiBase/api/tracking/day')
          .replace(queryParameters: {'dateIso': dateIso});

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_jwt',
          if ((_empId ?? '').isNotEmpty) 'x-empid': _empId!,
        },
      );

      if (res.statusCode == 401 || res.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load path: ${_safeMsg(res.body) ?? res.statusCode}')),
        );
        return;
      }
      if (res.statusCode >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load path: ${res.statusCode}')),
        );
        return;
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data == null || data['pathMap'] == null || (data['pathMap'] as List).isEmpty) {
        setState(() {
          _polylines = {};
          _markers = {};
          _circles = {};
          _center ??= const LatLng(12.9716, 77.5946);
        });
        return;
      }

      final List<dynamic> pts = data['pathMap'];
      final List<LatLng> latLngs = pts
          .map((e) => LatLng(
                (e['lat'] as num).toDouble(),
                (e['lng'] as num).toDouble(),
              ))
          .toList();

      final start = latLngs.first;
      final end = latLngs.last;

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: latLngs,
        width: 5,
      );

      final circles = <Circle>{
        for (int i = 0; i < latLngs.length; i++)
          Circle(
            circleId: CircleId('p$i'),
            center: latLngs[i],
            radius: 0.5,
            strokeWidth: 0,
            fillColor: Colors.deepPurpleAccent.withOpacity(0.85),
          )
      };

      final startMarker = Marker(
        markerId: const MarkerId('start'),
        position: start,
        infoWindow: const InfoWindow(title: 'Start'),
      );

      final endMarker = Marker(
        markerId: const MarkerId('end'),
        position: end,
        infoWindow: const InfoWindow(title: 'End'),
      );

      setState(() {
        _polylines = {polyline};
        _markers = {startMarker, endMarker};
        _circles = circles;
        _center = end;
      });

      if (_mapCtrl != null && latLngs.isNotEmpty) {
        await _mapCtrl!.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromLatLngs(latLngs), 48),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading path: $e')),
      );
    }
  }

  String? _safeMsg(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return (m['message'] ?? m['error'])?.toString();
    } catch (_) {
      return null;
    }
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in list) {
      minLat = (minLat == null) ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null) ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null) ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null) ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
      _loadAndDrawPath();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar (full width)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: kAppBarColor,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: kTextColor),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'My Track',
                      style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // Date
                    Expanded(
                      child: TextFormField(
                        controller: dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: "Choose date",
                          prefixIcon:
                              const Icon(Icons.calendar_today, color: kButtonColor),
                          filled: true,
                          fillColor: Colors.white,
                          border:
                              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kButtonColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shift (read-only look)
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Shift",
                          filled: true,
                          fillColor: Colors.white,
                          border:
                              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kButtonColor, width: 2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (selectedShift == null || selectedShift!.isEmpty)
                                  ? 'Shift'
                                  : selectedShift!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Map controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Map'),
                      selected: _mapType == MapType.normal,
                      onSelected: (_) => setState(() => _mapType = MapType.normal),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Satellite'),
                      selected: _mapType == MapType.satellite,
                      onSelected: (_) => setState(() => _mapType = MapType.satellite),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload path',
                      onPressed: _loadAndDrawPath,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Full-screen map (fills remaining height)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _center ?? const LatLng(12.9716, 77.5946),
                      zoom: 16,
                    ),
                    onMapCreated: (c) {
                      _mapCtrl = c;
                      if (_polylines.isNotEmpty) {
                        final pts = _polylines.first.points;
                        if (pts.isNotEmpty) {
                          _mapCtrl!.moveCamera(
                            CameraUpdate.newLatLngBounds(_boundsFromLatLngs(pts), 48),
                          );
                        }
                      }
                    },
                    mapType: _mapType,
                    polylines: _polylines,
                    markers: _markers,
                    circles: _circles,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
