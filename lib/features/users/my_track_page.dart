import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:serv_app/models/company_data.dart';
import 'package:flutter/foundation.dart';
import 'package:serv_app/services/api_service.dart';

void _log(Object msg) {
  if (kDebugMode) {
    print(msg);
  }
}

// ----- Theme -----
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ---------- Model ----------
class _TrackPoint {
  final double lat;
  final double lng;
  final DateTime ts;
  const _TrackPoint({required this.lat, required this.lng, required this.ts});
  LatLng get ll => LatLng(lat, lng);
}

// Haversine (meters)
double _distM(LatLng a, LatLng b) {
  const R = 6371000.0;
  final dLat = (b.latitude - a.latitude) * (3.141592653589793 / 180.0);
  final dLng = (b.longitude - a.longitude) * (3.141592653589793 / 180.0);
  final s1 = (dLat / 2.0).sin(), s2 = (dLng / 2.0).sin();
  final aa = s1 * s1 +
      (a.latitude * (3.14159 / 180.0)).cos() *
          (b.latitude * (3.14159 / 180.0)).cos() *
          s2 *
          s2;
  final c = 2.0 * aa.sqrt().atan2((1 - aa).sqrt());
  return R * c;
}

extension _NumMath on double {
  double sin() => Math.sin(this);
  double cos() => Math.cos(this);
  double sqrt() => Math.sqrt(this);
  double atan2(double x) => Math.atan2(this, x);
}

class Math {
  static double sin(double x) => MathInternal.sin(x);
  static double cos(double x) => MathInternal.cos(x);
  static double sqrt(double x) => MathInternal.sqrt(x);
  static double atan2(double y, double x) => MathInternal.atan2(y, x);
}

// ignore: avoid_classes_with_only_static_members
class MathInternal {
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double sqrt(double x) => math.sqrt(x);
  static double atan2(double y, double x) => math.atan2(y, x);
}

// Stable widget to prevent unnecessary GoogleMap rebuilds
class _StableGoogleMap extends StatelessWidget {
  final GoogleMapController? mapController;
  final Function(GoogleMapController) onMapCreated;
  final LatLng center;
  final MapType mapType;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final String emptyStateMessage;

  const _StableGoogleMap({
    super.key,
    required this.mapController,
    required this.onMapCreated,
    required this.center,
    required this.mapType,
    required this.polylines,
    required this.markers,
    required this.emptyStateMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          key: const ValueKey("my_track_google_map_stable"),
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 16,
          ),
          onMapCreated: onMapCreated,
          mapType: mapType,
          polylines: polylines,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: false,
        ),
        if (emptyStateMessage.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emptyStateMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
      ],
    );
  }
}

class MyTrackPage extends StatefulWidget {
  const MyTrackPage({super.key});
  @override
  State<MyTrackPage> createState() => _MyTrackPageState();
}

class _MyTrackPageState extends State<MyTrackPage> {
  // --- date control ---
  DateTime? selectedDate;
  bool _isTrackingLoading = false; // Single flag to prevent duplicate API calls
  final TextEditingController dateController = TextEditingController();

  // --- API base/token/empid ---
  final String _apiBase = ApiService.baseUrl;
  String? _jwt;
  String? _empId;

  // --- Tracking events state ---
  List<Map<String, dynamic>> _trackingEvents = [];
  bool _showTrackingEvents = false;

  // --- Google map state ---
  GoogleMapController? _mapCtrl;
  bool _mapControllerInitialized = false;
  MapType _mapType = MapType.normal;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _center;
  String _emptyStateMessage = '';

  // show end marker only after checkout
  bool _sessionEnded = false;

  final DateFormat _timeFmt = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();

    _jwt = CompanyData.token ?? '';
    _empId = CompanyData.empid;

    _log('TRACK INIT');

    final now = DateTime.now();
    selectedDate = now;
    dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // Call API once when page opens
    _loadAndDrawPath();
  }

  String _dateIso() {
    final d = selectedDate ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<_TrackPoint> _parseTrackPoints(List<dynamic> raw) {
    final pts = <_TrackPoint>[];
    debugPrint('[TRACKING] Parsing ${raw.length} raw points');

    for (final e in raw) {
      if (e is! Map) {
        continue;
      }

      final pointMap = e as Map<String, dynamic>;

      // Try different field name combinations
      final lat = (pointMap['lat'] as num?)?.toDouble() ??
          (pointMap['latitude'] as num?)?.toDouble() ??
          (pointMap['location']?['lat'] as num?)?.toDouble() ??
          (pointMap['coordinates']?[0] as num?)?.toDouble();

      final lng = (pointMap['lng'] as num?)?.toDouble() ??
          (pointMap['longitude'] as num?)?.toDouble() ??
          (pointMap['location']?['lng'] as num?)?.toDouble() ??
          (pointMap['coordinates']?[1] as num?)?.toDouble();

      final tsRaw = pointMap['ts'] ??
          pointMap['timestamp'] ??
          pointMap['time'] ??
          pointMap['createdAt'];

      if (lat == null || lng == null || tsRaw == null) {
        debugPrint('[TRACKING] Skipping point due to missing required fields');
        continue;
      }

      DateTime ts;
      if (tsRaw is String) {
        ts = DateTime.tryParse(tsRaw)?.toLocal() ?? DateTime.now();
      } else if (tsRaw is int) {
        ts = DateTime.fromMillisecondsSinceEpoch(tsRaw).toLocal();
      } else {
        debugPrint('[TRACKING] Skipping point due to invalid timestamp format');
        continue;
      }
      pts.add(_TrackPoint(lat: lat, lng: lng, ts: ts));
    }

    debugPrint('[TRACKING] Successfully parsed ${pts.length} points');
    pts.sort((a, b) => a.ts.compareTo(b.ts));
    return pts;
  }

  /// NEW: remove jitter before drawing — keeps first point, then
  /// only adds a point if moved >= [minMeters] from the last kept point.
  List<_TrackPoint> _simplifyByDistance(List<_TrackPoint> points,
      {double minMeters = 10}) {
    if (points.length <= 1) return points;
    final kept = <_TrackPoint>[points.first];
    for (var i = 1; i < points.length; i++) {
      final prev = kept.last.ll;
      final cur = points[i].ll;
      if (_distM(prev, cur) >= minMeters) {
        kept.add(points[i]);
      }
    }
    return kept;
  }

  List<Marker> _buildMarkers(List<_TrackPoint> points) {
    if (points.isEmpty) return const [];

    final markers = <Marker>[];

    // Start (green)
    final start = points.first;
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: start.ll,
        infoWindow: InfoWindow(title: 'Start • ${_timeFmt.format(start.ts)}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // All interior points (INCLUDING the last point when session not ended)
    for (var i = 1; i < points.length; i++) {
      // If session ended, the last point is reserved for the red "End" marker
      if (_sessionEnded && i == points.length - 1) continue;

      final p = points[i];
      markers.add(
        Marker(
          markerId: MarkerId('p$i'),
          position: p.ll,
          infoWindow: InfoWindow(title: _timeFmt.format(p.ts)),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // End (red) only if session ended
    if (_sessionEnded && points.length > 1) {
      final end = points.last;
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: end.ll,
          infoWindow: InfoWindow(title: 'End • ${_timeFmt.format(end.ts)}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  // --- Tracking Events Functions ---
  List<Map<String, dynamic>> _getTrackingEvents(Map<String, dynamic> data) {
    final raw = data['events'];
    if (raw is! List) return [];

    final events = raw
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((event) {
      final type = event['type']?.toString();
      return type == 'poor_gps' ||
          type == 'gps_disabled' ||
          type == 'account_logged_out' ||
          type == 'location_disabled' ||
          type == 'location_enabled';
    }).toList();

    events.sort((a, b) {
      final ta = _parseEventTs(a['ts']);
      final tb = _parseEventTs(b['ts']);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return events;
  }

  DateTime? _parseEventTs(dynamic tsRaw) {
    if (tsRaw == null) return null;

    if (tsRaw is int) {
      return DateTime.fromMillisecondsSinceEpoch(tsRaw).toLocal();
    }

    final stringValue = tsRaw.toString();
    final parsedIso = DateTime.tryParse(stringValue);
    if (parsedIso != null) return parsedIso.toLocal();

    final millis = int.tryParse(stringValue);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis).toLocal()
        : null;
  }

  String _formatTrackingEventType(String? type) {
    switch (type) {
      case 'poor_gps':
        return 'Poor GPS Accuracy';
      case 'gps_disabled':
        return 'GPS Disabled';
      case 'location_disabled':
        return 'Location Disabled by User';
      case 'account_logged_out':
        return 'Account Logged Out';
      case 'location_enabled':
        return 'Location Enabled by User';
      default:
        return type ?? 'Unknown Event';
    }
  }

  String _formatTrackingEventMessage(Map<String, dynamic> event) {
    final type = event['type']?.toString();

    if (type == 'poor_gps') {
      final accuracy = _toDoubleOrNull(event['accuracy']);
      if (accuracy != null) {
        return 'GPS accuracy was poor. Location point was skipped. Accuracy: ${accuracy.toStringAsFixed(1)}m';
      }
      return 'GPS accuracy was poor. Location point was skipped.';
    }

    if (type == 'gps_disabled') {
      return 'GPS/location service was disabled by the user.';
    }

    if (type == 'location_disabled') {
      return 'Location Disabled by User';
    }

    if (type == 'location_enabled') {
      return 'Location Enabled by User';
    }

    return event['message']?.toString() ?? _formatTrackingEventType(type);
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final d = double.tryParse(v);
      return d;
    }
    return null;
  }

  Widget _buildTrackingEventsSection() {
    // Show the button only after tracking data is loaded
    if (!_showTrackingEvents) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showTrackingEventsBottomSheet,
        icon: const Icon(Icons.event_note),
        label: const Text('View Tracking Events'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showTrackingEventsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tracking Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kButtonColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _trackingEvents.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No tracking events found for this day.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _trackingEvents.length,
                            itemBuilder: (context, index) {
                              final event = _trackingEvents[index];
                              final ts = _parseEventTs(event['ts']);
                              final timeLabel =
                                  ts != null ? _timeFmt.format(ts) : '-';
                              final typeLabel = _formatTrackingEventType(
                                event['type']?.toString(),
                              );
                              final message =
                                  _formatTrackingEventMessage(event);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD8C9F0),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      event['type']?.toString() ==
                                              'gps_disabled'
                                          ? Icons.location_off
                                          : Icons.gps_not_fixed,
                                      size: 24,
                                      color: kButtonColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$timeLabel - $typeLabel',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
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
            );
          },
        );
      },
    );
  }

  Future<void> _loadAndDrawPath() async {
    // Prevent duplicate API calls - only one request at a time
    if (_isTrackingLoading) {
      debugPrint(
          '[MY_TRACK] API call already in progress, skipping duplicate request');
      return;
    }

    _isTrackingLoading = true;

    try {
      if ((_jwt ?? '').isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in.')),
        );
        return;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/tracking/day')
          .replace(queryParameters: {'dateIso': _dateIso()});

      // Debug logs
      _log('TRACK INIT');

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_jwt',
        },
      ).timeout(const Duration(seconds: 15));

      _log('TRACK RES: ${res.statusCode}');

      // Handle 429 Too Many Requests error
      if (res.statusCode == 429) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Too many requests. Please wait a moment and try again.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (res.statusCode >= 400) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
        return;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data =
          (json['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;

      // Check if events exist in response
      final events = data['events'];
      if (events is List) {
        debugPrint('[MY_TRACK] events count: ${events.length}');
      }

      // Store tracking events
      _trackingEvents = _getTrackingEvents(data);
      debugPrint(
          '[MY_TRACK] Parsed tracking events count: ${_trackingEvents.length}');
      _showTrackingEvents = true;

      final endedAt = (data['endedAt'] as String?);
      _sessionEnded = (endedAt != null && endedAt.isNotEmpty);

      final dynamic pm = data['pathMap'];

      List<dynamic> raw;
      if (pm is List) {
        raw = pm;
      } else if (pm is Map) {
        final entries = pm.entries.toList()
          ..sort((a, b) => int.tryParse(a.key.toString())!
              .compareTo(int.tryParse(b.key.toString())!));
        raw = entries.map((e) => e.value).toList();
      } else {
        raw = const [];
      }

      debugPrint('[TRACKING] Raw points count: ${raw.length}');

      var points = _parseTrackPoints(raw);
      debugPrint('[MY_TRACK] parsed points count: ${points.length}');

      // TEMPORARY: Bypass simplification for debugging
      final simplified = points;
      debugPrint('[MY_TRACK] simplified points count: ${simplified.length}');

      if (points.isEmpty) {
        if (!mounted) return;
        setState(() {
          _polylines = {};
          _markers = {};
          _center ??= const LatLng(12.9716, 77.5946);
          _emptyStateMessage = 'No tracking points available for this date.';
        });
        return;
      }

      final latLngs = simplified.map((p) => p.ll).toList(growable: false);

      final Set<Polyline> polylines = (latLngs.length >= 2)
          ? {
              Polyline(
                polylineId: const PolylineId('route'),
                points: latLngs,
                width: 5,
                color: const Color(0xFFB39DDB),
              ),
            }
          : {};

      final markers = _buildMarkers(simplified);

      if (!mounted) return;
      setState(() {
        _polylines = polylines;
        _markers = {...markers};
        _center = latLngs.last;
        _emptyStateMessage = ''; // Clear empty state when points are loaded
      });

      // Only animate camera if map controller is initialized
      if (_mapCtrl != null && _mapControllerInitialized) {
        if (latLngs.length >= 2) {
          await _mapCtrl!.animateCamera(
            CameraUpdate.newLatLngBounds(_boundsFromLatLngs(latLngs), 48),
          );
        } else {
          await _mapCtrl!.animateCamera(
            CameraUpdate.newLatLngZoom(latLngs.first, 17),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading path: $e')));
    } finally {
      _isTrackingLoading = false; // Always reset flag in finally block
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Use real AppBar so global AppBarTheme applies everywhere
      appBar: AppBar(
        title: const Text('My Track'),
        actions: [
          IconButton(
            icon: _isTrackingLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Reload path',
            onPressed: _isTrackingLoading ? null : _loadAndDrawPath,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          top: false, // AppBar already handles status bar
          child: Column(
            children: [
              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: dateController,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: InputDecoration(
                              labelText: "Choose date",
                              prefixIcon: const Icon(Icons.calendar_today,
                                  color: kButtonColor),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kButtonColor, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Map type buttons - wrap to prevent overflow
                        Expanded(
                          flex: 1,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.start,
                            children: [
                              ChoiceChip(
                                label: const Text('Map'),
                                selected: _mapType == MapType.normal,
                                onSelected: (_) =>
                                    setState(() => _mapType = MapType.normal),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              ChoiceChip(
                                label: const Text('Satellite'),
                                selected: _mapType == MapType.satellite,
                                onSelected: (_) => setState(
                                    () => _mapType = MapType.satellite),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tracking Events Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildTrackingEventsSection(),
              ),

              // Map
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _StableGoogleMap(
                      mapController: _mapCtrl,
                      onMapCreated: (c) {
                        if (!mounted) return;
                        _mapCtrl = c;
                        _mapControllerInitialized = true;

                        // Animate camera to show the loaded path after map is ready
                        if (_polylines.isNotEmpty) {
                          final pts = _polylines.first.points;
                          if (pts.isNotEmpty) {
                            Future.microtask(() async {
                              if (_mapCtrl != null &&
                                  _mapControllerInitialized) {
                                if (pts.length >= 2) {
                                  await _mapCtrl!.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                        _boundsFromLatLngs(pts), 48),
                                  );
                                } else {
                                  await _mapCtrl!.animateCamera(
                                    CameraUpdate.newLatLngZoom(pts.first, 17),
                                  );
                                }
                              }
                            });
                          }
                        }
                      },
                      center: _center ?? const LatLng(12.9716, 77.5946),
                      mapType: _mapType,
                      polylines: _polylines,
                      markers: _markers,
                      emptyStateMessage: _emptyStateMessage,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> list) {
    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.longitude > maxLng) maxLng = latLng.longitude;
      if (latLng.longitude < minLng) minLng = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formattedDisplayDate = "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";

      setState(() {
        selectedDate = picked;
        dateController.text = formattedDisplayDate;
      });

      // Call existing tracking load method
      await _loadAndDrawPath();
    }
  }

  @override
  void dispose() {
    // Only dispose GoogleMapController if it was properly initialized
    if (_mapCtrl != null && _mapControllerInitialized) {
      _mapCtrl!.dispose();
      _mapCtrl = null;
      _mapControllerInitialized = false;
    }
    dateController.dispose();
    super.dispose();
  }
}
