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

  const _TrackPoint({
    required this.lat,
    required this.lng,
    required this.ts,
  });

  LatLng get ll => LatLng(lat, lng);
}

class _TrackingEvent {
  final String type;
  final String message;
  final String? reason;
  final double? accuracy;
  final DateTime? ts;

  const _TrackingEvent({
    required this.type,
    required this.message,
    this.reason,
    this.accuracy,
    this.ts,
  });

  factory _TrackingEvent.fromJson(Map<String, dynamic> json) {
    return _TrackingEvent(
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      reason: json['reason']?.toString(),
      accuracy: json['accuracy'] != null
          ? double.tryParse(json['accuracy'].toString())
          : null,
      ts: json['ts'] != null
          ? DateTime.tryParse(json['ts'].toString())?.toLocal()
          : null,
    );
  }
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

class MyTrackPage extends StatefulWidget {
  const MyTrackPage({super.key});

  @override
  State<MyTrackPage> createState() => _MyTrackPageState();
}

class _MyTrackPageState extends State<MyTrackPage> {
  // --- date control ---
  DateTime? selectedDate;
  bool _isLoadingPath = false;
  final TextEditingController dateController = TextEditingController();

  // --- API base/token/empid ---
  final String _apiBase = ApiService.baseUrl;
  String? _jwt;
  String? _empId;

  // --- Google map state ---
  GoogleMapController? _mapCtrl;
  bool _mapControllerInitialized = false;
  MapType _mapType = MapType.normal;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _center;
  String _emptyStateMessage = '';
  List<_TrackingEvent> _trackingEvents = [];

  // show end marker only after checkout
  bool _sessionEnded = false;

  final DateFormat _timeFmt = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();

    _jwt = CompanyData.token ?? '';
    _empId = CompanyData.empid;

    _log('TRACK INIT: jwt=${_jwt?.length ?? 0} empid=${_empId?.length ?? 0}');

    final now = DateTime.now();
    selectedDate = now;
    dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    _loadAndDrawPath();
  }

  String _dateIso() {
    final d = selectedDate ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<_TrackingEvent> _parseTrackingEvents(dynamic raw) {
    if (raw is! List) return [];

    final events = raw
        .whereType<Map>()
        .map((e) => _TrackingEvent.fromJson(Map<String, dynamic>.from(e)))
        .where(
          (e) =>
              e.type == 'poor_gps' ||
              e.type == 'gps_disabled' ||
              e.type == 'account_logged_out',
        )
        .toList();

    events.sort((a, b) {
      final at = a.ts;
      final bt = b.ts;

      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;

      return bt.compareTo(at);
    });

    return events;
  }

  List<_TrackPoint> _parseTrackPoints(List<dynamic> raw) {
    final pts = <_TrackPoint>[];
    debugPrint('[TRACKING] Parsing ${raw.length} raw points');

    for (final e in raw) {
      if (e is! Map) {
        debugPrint('[TRACKING] Skipping non-Map point: $e');
        continue;
      }

      final pointMap = e as Map<String, dynamic>;
      debugPrint('[TRACKING] Processing point with keys: ${pointMap.keys.toList()}');

      // Try different field name combinations
      final lat = (pointMap['lat'] as num?)?.toDouble() ??
          (pointMap['latitude'] as num?)?.toDouble() ??
          (pointMap['location']?['lat'] as num?)?.toDouble() ??
          (pointMap['coordinates']?[0] as num?)?.toDouble();

      final lng = (pointMap['lng'] as num?)?.toDouble() ??
          (pointMap['longitude'] as num?)?.toDouble() ??
          (pointMap['location']?['lng'] as num?)?.toDouble() ??
          (pointMap['coordinates']?[1] as num?)?.toDouble();

      final tsRaw =
          pointMap['ts'] ?? pointMap['timestamp'] ?? pointMap['time'] ?? pointMap['createdAt'];

      debugPrint('[TRACKING] Point fields - lat: $lat, lng: $lng, ts: $tsRaw');

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
        debugPrint('[TRACKING] Skipping point due to invalid timestamp format: $tsRaw');
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
  List<_TrackPoint> _simplifyByDistance(
    List<_TrackPoint> points, {
    double minMeters = 10,
  }) {
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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

  Future<void> _loadAndDrawPath() async {
    if (_isLoadingPath) return;
    setState(() => _isLoadingPath = true);

    try {
      if ((_jwt ?? '').isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in.')),
        );
        return;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/tracking/day').replace(
        queryParameters: {
          'empid': _empId ?? '',
          'dateIso': _dateIso(),
        },
      );

      // Debug logs
      print("TRACKING API DATE: ${_dateIso()}");
      print("TRACKING API URL: $uri");

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_jwt',
          if ((_empId ?? '').isNotEmpty) 'x-empid': _empId!,
        },
      ).timeout(const Duration(seconds: 15));

      _log('TRACK RES: ${res.statusCode}');
      debugPrint('[MY_TRACK] Full response body: ${res.body}');

      if (res.statusCode >= 400) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res.statusCode}')),
        );
        return;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (json['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;

      final endedAt = (data['endedAt'] as String?);
      _sessionEnded = (endedAt != null && endedAt.isNotEmpty);

      final parsedEvents = _parseTrackingEvents(data['events']);

      final dynamic pm = data['pathMap'];
      debugPrint('[TRACKING] Raw pathMap data: $pm');

      List<dynamic> raw;

      if (pm is List) {
        raw = pm;
      } else if (pm is Map) {
        final entries = pm.entries.toList()
          ..sort(
            (a, b) => int
                .tryParse(a.key.toString())!
                .compareTo(int.tryParse(b.key.toString())!),
          );
        raw = entries.map((e) => e.value).toList();
      } else {
        raw = const [];
      }

      debugPrint('[TRACKING] Raw points count: ${raw.length}');
      if (raw.isNotEmpty) {
        debugPrint('[TRACKING] First raw point: ${raw.first}');
      }

      var points = _parseTrackPoints(raw);
      debugPrint('[MY_TRACK] parsed points count: ${points.length}');

      if (points.isNotEmpty) {
        debugPrint(
          '[MY_TRACK] First parsed point: lat=${points.first.lat}, lng=${points.first.lng}',
        );
        debugPrint(
          '[MY_TRACK] Last parsed point: lat=${points.last.lat}, lng=${points.last.lng}',
        );
      }

      // TEMPORARY: Bypass simplification for debugging
      final simplified = points;
      debugPrint('[MY_TRACK] simplified points count (bypass): ${simplified.length}');

      if (simplified.isNotEmpty) {
        for (int i = 0; i < simplified.length; i++) {
          debugPrint(
            '[MY_TRACK] Point[$i]: lat=${simplified[i].lat}, lng=${simplified[i].lng}, ts=${simplified[i].ts}',
          );
        }
      }

      if (points.isEmpty) {
        if (!mounted) return;
        setState(() {
          _polylines = {};
          _markers = {};
          _center ??= const LatLng(12.9716, 77.5946);
          _emptyStateMessage = 'No tracking points available for this date.';
          _trackingEvents = parsedEvents;
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
        _emptyStateMessage = '';
        _trackingEvents = parsedEvents;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading path: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPath = false);
      }
    }
  }

  Widget _buildTrackingEventsButton() {
    if (_trackingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showTrackingEventsBottomSheet,
          icon: const Icon(Icons.warning_amber_rounded),
          label: Text('View Tracking Events (${_trackingEvents.length})'),
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
    );
  }

  void _showTrackingEventsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.40,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tracking Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _trackingEvents.length,
                      itemBuilder: (context, index) {
                        return _buildTrackingEventItem(_trackingEvents[index]);
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

  Widget _buildTrackingEventItem(_TrackingEvent event) {
    final timeText = event.ts == null ? '--:--' : _timeFmt.format(event.ts!);
    final bool isGpsDisabled = event.type == 'gps_disabled';
    final bool isLoggedOut = event.type == 'account_logged_out';

    final title = isLoggedOut
        ? 'Account Logged Out'
        : isGpsDisabled
            ? 'GPS Disabled'
            : 'Poor GPS Accuracy';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8C9F0)),
      ),
      child: Row(
        children: [
          Icon(
            isLoggedOut
                ? Icons.logout
                : isGpsDisabled
                    ? Icons.location_off
                    : Icons.gps_not_fixed,
            size: 22,
            color: kButtonColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$timeText - $title',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Use real AppBar so global AppBarTheme applies everywhere
      appBar: AppBar(
        title: const Text('My Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload path',
            onPressed: _loadAndDrawPath,
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
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: kButtonColor,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kButtonColor,
                                  width: 2,
                                ),
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
                                onSelected: (_) =>
                                    setState(() => _mapType = MapType.satellite),
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

              // Map
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        GoogleMap(
                          key: const ValueKey("my_track_google_map"),
                          initialCameraPosition: CameraPosition(
                            target: _center ?? const LatLng(12.9716, 77.5946),
                            zoom: 16,
                          ),
                          onMapCreated: (c) {
                            if (!mounted) return;
                            _mapCtrl = c;
                            _mapControllerInitialized = true;

                            if (_polylines.isNotEmpty) {
                              final pts = _polylines.first.points;

                              if (pts.isNotEmpty) {
                                _mapCtrl!.moveCamera(
                                  CameraUpdate.newLatLngBounds(
                                    _boundsFromLatLngs(pts),
                                    48,
                                  ),
                                );
                              }
                            }
                          },
                          mapType: _mapType,
                          polylines: _polylines,
                          markers: _markers,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          compassEnabled: false,
                        ),
                        if (_emptyStateMessage.isNotEmpty)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _emptyStateMessage,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildTrackingEventsButton(),
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
      final formattedDisplayDate =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";

      setState(() {
        selectedDate = picked;
        dateController.text = formattedDisplayDate;
      });

      // Debug logs
      print("DATE PICKER SELECTED DATE: $picked");

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