// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';

// // Theme constants
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8c6eaf);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class LocationModel {
//   final String address;
//   final double radius;
//   final LatLng latLng;

//   LocationModel({
//     required this.address,
//     required this.radius,
//     required this.latLng,
//   });
// }

// class OfficeLocationPage extends StatefulWidget {
//   const OfficeLocationPage({super.key});

//   @override
//   State<OfficeLocationPage> createState() => _OfficeLocationPageState();
// }

// class _OfficeLocationPageState extends State<OfficeLocationPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final MapController _mapController = MapController();
//   final List<LocationModel> _locations = [];

//   LatLng _mapCenter = LatLng(20.5937, 78.9629); // Default India
//   LatLng? _currentLocation;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();

//     final defaultLocation = LocationModel(
//       address: 'Chennai, Tamil Nadu, India',
//       radius: 100,
//       latLng: LatLng(13.0827, 80.2707),
//     );
//     _locations.add(defaultLocation);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _mapController.move(defaultLocation.latLng, 12.0);
//     });
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) return;

//     final position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _currentLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   Future<LatLng?> _geocodeAddress(String address) async {
//     final url = Uri.parse(
//       'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1',
//     );
//     final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data.isNotEmpty) {
//         return LatLng(
//           double.parse(data[0]['lat']),
//           double.parse(data[0]['lon']),
//         );
//       }
//     }
//     return null;
//   }

//   void _addOrEditLocation({int? indexToEdit}) {
//     final isEdit = indexToEdit != null;

//     final addressController = TextEditingController(
//       text: isEdit ? _locations[indexToEdit].address : _searchController.text,
//     );
//     final radiusController = TextEditingController(
//       text: isEdit ? _locations[indexToEdit].radius.toString() : '',
//     );
//     final latController = TextEditingController(
//       text: isEdit ? _locations[indexToEdit].latLng.latitude.toString() : '',
//     );
//     final lngController = TextEditingController(
//       text: isEdit ? _locations[indexToEdit].latLng.longitude.toString() : '',
//     );

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(isEdit ? 'Edit Location' : 'Add Office Branch'),
//         content: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: addressController,
//                 decoration: const InputDecoration(labelText: 'Address'),
//                 maxLines: 2,
//               ),
//               TextField(
//                 controller: radiusController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Radius (meters)'),
//               ),
//               TextField(
//                 controller: latController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Latitude (optional)',
//                 ),
//               ),
//               TextField(
//                 controller: lngController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Longitude (optional)',
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final address = addressController.text.trim();
//               final radius = double.tryParse(radiusController.text) ?? 100.0;
//               double? lat = double.tryParse(latController.text.trim());
//               double? lng = double.tryParse(lngController.text.trim());

//               LatLng? coords = (lat != null && lng != null)
//                   ? LatLng(lat, lng)
//                   : await _geocodeAddress(address);

//               if (coords == null) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Could not determine location')),
//                 );
//                 return;
//               }

//               setState(() {
//                 final newLocation = LocationModel(
//                   address: address,
//                   radius: radius,
//                   latLng: coords,
//                 );
//                 if (isEdit) {
//                   _locations[indexToEdit] = newLocation;
//                 } else {
//                   _locations.add(newLocation);
//                 }
//                 _mapCenter = coords;
//                 _mapController.move(coords, 15.5);
//                 _searchController.clear();
//               });

//               Navigator.pop(context);
//             },
//             child: Text(isEdit ? 'Update' : 'Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deleteLocation(int index) {
//     setState(() {
//       _locations.removeAt(index);
//     });
//   }

//   void _openInMaps() async {
//     final lat = _mapCenter.latitude;
//     final lng = _mapCenter.longitude;
//     final uri = Uri.parse(
//       'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
//     );
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Could not launch Maps')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(65),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: kAppBarColor,
//             elevation: 4,
//             flexibleSpace: SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: kTextColor),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const Text(
//                         'Office Location',
//                         style: TextStyle(fontSize: 18, color: kTextColor),
//                       ),
//                     ],
//                   ),
//                   // ❌ Removed the instruction text from here
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               // ✅ Instruction moved here
//               const Padding(
//                 padding: EdgeInsets.only(bottom: 8.0),
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     'Add the offices or locations where your team members will be checking in and checkout',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),
//               Row(
//                 children: [
//                   const Icon(Icons.search, size: 24),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: const InputDecoration(
//                         hintText: 'Search Location',
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     icon: const Icon(Icons.add),
//                     onPressed: () => _addOrEditLocation(),
//                     label: const Text(' Add More'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: kButtonColor,
//                       foregroundColor: kTextColor,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: ListView.separated(
//                   itemCount: _locations.length,
//                   separatorBuilder: (_, __) => const Divider(),
//                   itemBuilder: (context, index) {
//                     final loc = _locations[index];
//                     return ListTile(
//                       title: Text(loc.address.split(',').first),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Radius: ${loc.radius.toStringAsFixed(0)}M'),
//                           Text(loc.address),
//                         ],
//                       ),
//                       onTap: () {
//                         _mapController.move(loc.latLng, 16.0);
//                         setState(() => _mapCenter = loc.latLng);
//                       },
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () =>
//                                 _addOrEditLocation(indexToEdit: index),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete),
//                             onPressed: () => _deleteLocation(index),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   final count = _locations.length;
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Number of Locations: $count')),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kButtonColor,
//                   foregroundColor: kTextColor,
//                 ),
//                 child: const Text("Number Of Locations"),
//               ),
//               const SizedBox(height: 10),
//               Stack(
//                 children: [
//                   SizedBox(
//                     height: 260,
//                     child: FlutterMap(
//                       mapController: _mapController,
//                       options: MapOptions(
//                         center: _mapCenter,
//                         zoom: 6.0,
//                         interactiveFlags: InteractiveFlag.all,
//                       ),
//                       children: [
//                         TileLayer(
//                           urlTemplate:
//                               'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                           subdomains: ['a', 'b', 'c'],
//                           userAgentPackageName: 'com.example.app',
//                         ),
//                         MarkerLayer(
//                           markers: [
//                             if (_currentLocation != null)
//                               Marker(
//                                 width: 60,
//                                 height: 60,
//                                 point: _currentLocation!,
//                                 child: const Icon(
//                                   Icons.person_pin_circle,
//                                   color: Colors.green,
//                                   size: 40,
//                                 ),
//                               ),
//                             ..._locations.map(
//                               (loc) => Marker(
//                                 width: 80.0,
//                                 height: 80.0,
//                                 point: loc.latLng,
//                                 child: const Icon(
//                                   Icons.location_on,
//                                   color: Colors.red,
//                                   size: 40,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   Positioned(
//                     right: 8,
//                     bottom: 8,
//                     child: ElevatedButton.icon(
//                       onPressed: _openInMaps,
//                       icon: const Icon(Icons.map),
//                       label: const Text("Open in Maps"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: kAppBarColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8c6eaf);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class LocationModel {
  final String address;
  final double radius;
  final LatLng latLng;

  LocationModel({
    required this.address,
    required this.radius,
    required this.latLng,
  });
}

class OfficeLocationPage extends StatefulWidget {
  const OfficeLocationPage({super.key});

  @override
  State<OfficeLocationPage> createState() => _OfficeLocationPageState();
}

class _OfficeLocationPageState extends State<OfficeLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final List<LocationModel> _locations = [];

  LatLng _mapCenter = LatLng(20.5937, 78.9629);
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    final defaultLocation = LocationModel(
      address: 'Chennai, Tamil Nadu, India',
      radius: 100,
      latLng: LatLng(13.0827, 80.2707),
    );
    _locations.add(defaultLocation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(defaultLocation.latLng, 12.0);
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1',
    );
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
      }
    }
    return null;
  }

  void _addOrEditLocation({int? indexToEdit}) {
    final isEdit = indexToEdit != null;
    final addressController = TextEditingController(
      text: isEdit ? _locations[indexToEdit].address : _searchController.text,
    );
    final radiusController = TextEditingController(
      text: isEdit ? _locations[indexToEdit].radius.toString() : '',
    );
    final latController = TextEditingController(
      text: isEdit ? _locations[indexToEdit].latLng.latitude.toString() : '',
    );
    final lngController = TextEditingController(
      text: isEdit ? _locations[indexToEdit].latLng.longitude.toString() : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Location' : 'Add Office Branch'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
              ),
              TextField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude (optional)'),
              ),
              TextField(
                controller: lngController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final address = addressController.text.trim();
              final radius = double.tryParse(radiusController.text) ?? 100.0;
              double? lat = double.tryParse(latController.text.trim());
              double? lng = double.tryParse(lngController.text.trim());
              LatLng? coords = (lat != null && lng != null)
                  ? LatLng(lat, lng)
                  : await _geocodeAddress(address);

              if (coords == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not determine location')),
                );
                return;
              }

              setState(() {
                final newLocation = LocationModel(
                  address: address,
                  radius: radius,
                  latLng: coords,
                );
                if (isEdit) {
                  _locations[indexToEdit] = newLocation;
                } else {
                  _locations.add(newLocation);
                }
                _mapCenter = coords;
                _mapController.move(coords, 15.5);
                _searchController.clear();
              });

              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteLocation(int index) {
    setState(() {
      _locations.removeAt(index);
    });
  }

  void _openInMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_mapCenter.latitude},${_mapCenter.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: kAppBarColor,
          title: const Text('Office Location', style: TextStyle(color: kTextColor)),
          leading: BackButton(color: kTextColor),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add the offices or locations where your team members will be checking in and checkout',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: 'Search Location'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addOrEditLocation,
                      icon: const Icon(Icons.add),
                      label: const Text('Add More'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        foregroundColor: kTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _locations.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return ListTile(
                      title: Text(loc.address.split(',').first),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Radius: ${loc.radius.toStringAsFixed(0)}M'),
                          Text(loc.address),
                        ],
                      ),
                      onTap: () {
                        _mapController.move(loc.latLng, 16.0);
                        setState(() => _mapCenter = loc.latLng);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditLocation(indexToEdit: index)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteLocation(index)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _mapCenter,
                          zoom: 6.0,
                          interactiveFlags: InteractiveFlag.all,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 40),
                                ),
                              ..._locations.map((loc) => Marker(
                                    point: loc.latLng,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  )),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: ElevatedButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.map),
                          label: const Text("Open in Maps"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kAppBarColor,
                          ),
                        ),
                      ),
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
}