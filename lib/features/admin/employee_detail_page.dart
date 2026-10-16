import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

// 👇 Added for gesture recognizers so the map can pan/zoom inside ListView
import 'package:flutter/gestures.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/utils/office_presence.dart';
import 'package:serv_app/features/admin/admin_theme.dart';
import 'package:serv_app/features/admin/tracking_status.dart';

// Theme
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF6A1B9A);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/* ---------- Tracking helpers (match My Track) ---------- */

class _TrackPoint {
  final double lat;
  final double lng;
  final DateTime ts;
  const _TrackPoint(this.lat, this.lng, this.ts);
  LatLng get ll => LatLng(lat, lng);
}

// Haversine (meters)
double _distM(LatLng a, LatLng b) {
  const R = 6371000.0;
  final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
  final dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
  final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(a.latitude * math.pi / 180.0) *
          math.cos(b.latitude * math.pi / 180.0) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2.0 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
  return R * c;
}

/// Keep first point, then only add if moved >= minMeters
List<_TrackPoint> _simplifyByDistance(
  List<_TrackPoint> points, {
  double minMeters = 10,
}) {
  if (points.length <= 1) return points;
  final kept = <_TrackPoint>[points.first];

  for (var i = 1; i < points.length; i++) {
    if (_distM(kept.last.ll, points[i].ll) >= minMeters) {
      kept.add(points[i]);
    }
  }

  return kept;
}

class EmployeeDetailPage extends StatefulWidget {
  final Map<String, dynamic>
      employee; // at least {'id': empid}, optional {'date': 'YYYY-MM-DD'}
  const EmployeeDetailPage({super.key, required this.employee});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  bool _loading = true;
  String? _error;
  bool _loadingDetails = false;

  // From backend (attendance)
  late String empid;
  late String dateIso;
  String name = '-';
  String shift = '-';
  String department = '-';
  String branchName = '-'; // attendance.branchName
  String status = '-';
  String? checkIn; // HH:mm:ss
  String? checkOut; // HH:mm:ss

  // Stored check-in coordinates (attendance.checkInLatitude/Longitude)
  double? checkInLat;
  double? checkInLng;
  double? checkInAccuracy;

  // Stored check-out coordinates & office-presence classification
  double? checkOutLat;
  double? checkOutLng;
  double? checkOutAccuracy;
  double? distanceFromBranch;
  String? officePresence;
  String? checkOutOfficePresence;

  // Branch (expected) coordinates (attendance.expectedLatitude/Longitude)
  double? expectedLat;
  double? expectedLng;

  // Google Map
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  CameraPosition _initialCam = const CameraPosition(
      target: LatLng(13.0827, 80.2707), zoom: 16); // Chennai

  // Tracking UI parity with My Track
  final DateFormat _timeFmt = DateFormat('hh:mm a');
  bool _sessionEnded = false;
  Map<String, dynamic>? _cachedTrackingDay;
  bool _trackingLoaded = false; // red end pin only if true
  bool _showTrackingEvents = false;
  List<Map<String, dynamic>> _trackingEvents = [];

  // ── live status (Phase 2A/2E) ────────────────────────────────────────
  // 60s auto-refresh while the page shows TODAY's tracking session. The
  // status itself comes from the backend (trackingStatus in /tracking/day)
  // so this page can never disagree with the live dashboard.
  static const Duration _kAutoRefresh = Duration(seconds: 60);
  Timer? _autoRefreshTimer;

  // Date picker state
  DateTime? selectedDate;
  bool _isLoadingPath = false;
  final TextEditingController dateController = TextEditingController();
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    empid =
        (widget.employee['id'] ?? widget.employee['empid'] ?? '').toString();
    final passedDate = (widget.employee['date'] ?? '').toString();
    dateIso = passedDate.isNotEmpty
        ? passedDate
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Initialize date picker with today
    final now = DateTime.now();
    selectedDate = now;
    dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    _loadLiveDetails();
    // Load tracking immediately so the status card + history are visible
    // without pressing "Geolocation" first. Silent: an absent or failed
    // load must not block the attendance details that already loaded.
    _loadTrackingDay(silent: true, fitCamera: true);
    _autoRefreshTimer = Timer.periodic(_kAutoRefresh, (_) {
      _autoRefresh();
    });
  }

  bool _viewingToday() => _dateIso() ==
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Periodic refresh while today's session can still change. Stops on
  /// checkout (session ended) or when a past date is selected - nothing
  /// left to update.
  Future<void> _autoRefresh() async {
    if (!mounted || !_viewingToday() || _sessionEnded) return;
    await _loadLiveDetails(silent: true);
    await _loadTrackingDay(silent: true, fitCamera: false);
    if (_sessionEnded) _autoRefreshTimer?.cancel();
  }

  void _renderTrackingPath(Map<String, dynamic> data,
      {bool fitCamera = true, bool notifyEmpty = true}) {
    _sessionEnded =
        (data['endedAt'] != null && '${data['endedAt']}'.isNotEmpty);

    final raw = (data['pathMap'] is List) ? List.from(data['pathMap']) : [];

    final pts = <_TrackPoint>[];
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      final lat = _toDoubleOrNull(m['lat']);
      final lng = _toDoubleOrNull(m['lng']);
      final tsRaw = (m['ts'] ?? '').toString();
      if (lat == null || lng == null) continue;

      DateTime ts;
      final tryIso = DateTime.tryParse(tsRaw);
      if (tryIso != null) {
        ts = tryIso.toLocal();
      } else {
        final millis = int.tryParse(tsRaw);
        ts = millis != null
            ? DateTime.fromMillisecondsSinceEpoch(millis).toLocal()
            : DateTime.now();
      }

      pts.add(_TrackPoint(lat, lng, ts));
    }

    if (pts.isEmpty) {
      if (notifyEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No path data found for this day.')),
        );
      }
      return;
    }

    // Same behavior as My Track page: do not simplify points.
    final points = pts;
    final latLngs = points.map((p) => p.ll).toList(growable: false);

    final mk = <Marker>{};

    final start = points.first;
    mk.add(
      Marker(
        markerId: const MarkerId('start'),
        position: start.ll,
        infoWindow: InfoWindow(title: 'Start • ${_timeFmt.format(start.ts)}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    for (var i = 1; i < points.length; i++) {
      if (_sessionEnded && i == points.length - 1) continue;

      final p = points[i];
      mk.add(
        Marker(
          markerId: MarkerId('p$i'),
          position: p.ll,
          infoWindow: InfoWindow(title: _timeFmt.format(p.ts)),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (_sessionEnded && points.length > 1) {
      final end = points.last;
      mk.add(
        Marker(
          markerId: const MarkerId('end'),
          position: end.ll,
          infoWindow: InfoWindow(title: 'End • ${_timeFmt.format(end.ts)}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    final poly = Polyline(
      polylineId: const PolylineId('path'),
      points: latLngs,
      width: 6,
      color: const Color(0xFF7B5CD6),
    );

    setState(() {
      _markers
        ..clear()
        ..addAll(mk);
      _polylines
        ..clear()
        ..add(poly);
    });

    if (fitCamera) _fitCameraToAll(latLngs, padding: 72.0);
  }

  // ----------- Load live details (attendance for the given emp/date) -----------
  Future<void> _loadLiveDetails({bool silent = false}) async {
    if (_loadingDetails) return;
    _loadingDetails = true;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        if ((CompanyData.token ?? '').isNotEmpty)
          'Authorization': 'Bearer ${CompanyData.token}',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/liveEmployeeDetails/$empid')
          .replace(queryParameters: {'dateIso': dateIso});

      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}: ${resp.body}';
      }

      final body = jsonDecode(resp.body);
      final data = (body is Map && body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'])
          : <String, dynamic>{};

      setState(() {
        name = (data['name'] ?? '-') as String;
        shift = (data['shiftGroup'] ?? data['shift'] ?? '-') as String;
        department = (data['dept'] ?? data['department'] ?? '-') as String;
        branchName = (data['location'] ?? '-')
            as String; // server sends branchName as 'location'
        status = (data['status'] ?? '-') as String;

        final ci = (data['checkIn'] as String?);
        checkIn = (ci == null || ci.trim().isEmpty) ? null : ci;

        final co = (data['checkOut'] as String?);
        checkOut = (co == null || co.trim().isEmpty) ? null : co;

        // Server returns check-in lat/lng in top-level latitude/longitude
        checkInLat = _toDoubleOrNull(data['latitude']);
        checkInLng = _toDoubleOrNull(data['longitude']);
        checkInAccuracy = _toDoubleOrNull(data['checkInAccuracy']);

        // Check-out fix + office-presence classification
        checkOutLat = _toDoubleOrNull(data['checkOutLatitude']);
        checkOutLng = _toDoubleOrNull(data['checkOutLongitude']);
        checkOutAccuracy = _toDoubleOrNull(data['checkOutAccuracy']);
        distanceFromBranch = _toDoubleOrNull(
            data['distanceFromBranch'] ?? data['geofenceMeters']);
        officePresence = data['officePresence']?.toString();
        checkOutOfficePresence =
            data['checkOutOfficePresence']?.toString();

        // If backend provided expected coordinates & branch name, store them
        expectedLat = _toDoubleOrNull(data['expectedLatitude']);
        expectedLng = _toDoubleOrNull(data['expectedLongitude']);
      });

      // Default map to check-in point if present
      if (checkInLat != null && checkInLng != null) {
        _showCheckInOnMap();
      } else {
        setState(() {
          _markers.clear();
          _polylines.clear();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EMP_DETAIL] Failed to load employee details');
      }

      // Silent refreshes keep the last known details on screen.
      if (!silent) {
        setState(() => _error = 'Failed to load employee details');
      }
    } finally {
      _loadingDetails = false;
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final d = double.tryParse(v);
      return d;
    }
    return null;
  }

  List<Map<String, dynamic>> _getTrackingEvents(Map<String, dynamic> data) {
    final raw = data['events'];

    if (raw is! List) {
      return [];
    }

    final events = raw
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((event) {
      final type = event['type']?.toString();
      return type == 'poor_gps' ||
          type == 'gps_disabled' ||
          type == 'location_disabled' ||
          type == 'location_enabled' ||
          type == 'mock_location_detected' ||
          type == 'impossible_travel' ||
          type == 'permission_revoked' ||
          type == 'suspicious_location' ||
          type == 'account_logged_out';
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
      case 'mock_location_detected':
        return 'Suspicious / Mock Location Detected';
      case 'impossible_travel':
        return 'Unrealistic Movement Detected';
      case 'permission_revoked':
        return 'Location Permission Revoked';
      case 'suspicious_location':
        return 'Suspicious Location';
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

    if (type == 'permission_revoked') {
      return 'Location permission was revoked or is unavailable. '
          'Tracking cannot record GPS points until it is restored.';
    }

    // Server-generated flag events carry their own factual message
    // ("Tracking point flagged: mock_location, impossible_speed").
    if (type == 'suspicious_location') {
      return event['message']?.toString() ??
          'A tracking point was flagged for review.';
    }

    return event['message']?.toString() ?? _formatTrackingEventType(type);
  }

  /// Optional "lat, lng (±accuracy)" line shown under the event message when
  /// the backend recorded coordinates for the event.
  String? _trackingEventCoordsText(Map<String, dynamic> event) {
    final lat = _toDoubleOrNull(event['latitude']);
    final lng = _toDoubleOrNull(event['longitude']);
    if (lat == null || lng == null) return null;
    final acc = _toDoubleOrNull(event['accuracy']);
    final accPart = acc != null ? '  (±${acc.toStringAsFixed(0)}m)' : '';
    return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}$accPart';
  }

  IconData _trackingEventIcon(String? type) {
    switch (type) {
      case 'gps_disabled':
      case 'location_disabled':
        return Icons.location_off;
      case 'location_enabled':
        return Icons.location_on;
      case 'permission_revoked':
        return Icons.gps_off;
      case 'suspicious_location':
        return Icons.warning_amber_rounded;
      case 'account_logged_out':
        return Icons.logout;
      default:
        return Icons.gps_not_fixed;
    }
  }

  String? _trackingEventDurationText(int index) {
    final event = _trackingEvents[index];
    final type = event['type']?.toString();

    if (type != 'gps_disabled') return null;

    final start = _parseEventTs(event['ts']);
    if (start == null) return null;

    // TODO: implement duration calculation
  }

  Widget _buildTrackingEventsSection() {
    // Show the button only after the Geolocation button loads tracking data.
    // This keeps the employee detail card clean and avoids showing events directly on the page.

    if (!_showTrackingEvents) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showTrackingEventsBottomSheet,
        icon: const Icon(Icons.event_note),
        label: const Text('View Tracking Event'),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tracking Events',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kButtonColor,
                                ),
                              ),
                              Text(
                                '$name  •  $empid',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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
                              final durationText =
                                  _trackingEventDurationText(index);
                              final coordsText =
                                  _trackingEventCoordsText(event);

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
                                      _trackingEventIcon(
                                          event['type']?.toString()),
                                      size: 24,
                                      color: event['type']?.toString() ==
                                              'suspicious_location'
                                          ? Colors.orange.shade800
                                          : kButtonColor,
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
                                          const SizedBox(height: 5),
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (coordsText != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              coordsText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                          if (durationText != null) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              durationText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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

  /// 1) Check-in Location — show stored attendance check-in coords (green pin)
  void _showCheckInOnMap() {
    if (checkInLat == null || checkInLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No stored check-in location for this day.')),
      );
    } else {
      final pos = LatLng(checkInLat!, checkInLng!);

      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('checkin'),
            position: pos,
            infoWindow: const InfoWindow(title: 'Check-in location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
        );

      _polylines.clear();

      _animate(pos, 18);
    }

    setState(() {});
  }

  /// 2) Geolocation — draw FULL path for the day from tracking collection.
  ///    Start: green default marker (index 0)
  ///    Interior points (1..N-1): orange pins with local time
  ///    End: red pin only if the session ended (endedAt present)
  Future<void> _showLastTrackingPath() =>
      _loadTrackingDay(silent: false, fitCamera: true);

  /// Fetches /tracking/day for the selected date. Silent mode (auto-load,
  /// auto-refresh) never shows snackbars/spinners and keeps the last known
  /// data on failure.
  Future<void> _loadTrackingDay(
      {required bool silent, bool fitCamera = true}) async {
    if (_isLoadingPath) return;
    _isLoadingPath = true;
    if (!silent) setState(() {});

    // Use selected date from date picker
    final selectedDateIso = _dateIso();

    // Always fetch fresh data when date changes (cache is cleared in _pickDate)
    // Only use cache if we're loading the same date again without changing it
    if (!silent && _trackingLoaded && _cachedTrackingDay != null) {
      final data = _cachedTrackingDay!;
      _trackingEvents = _getTrackingEvents(data);
      _showTrackingEvents = true;
      _renderTrackingPath(data, fitCamera: fitCamera);
      _isLoadingPath = false;
      if (!silent) setState(() {});
      return;
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-empid': empid,
        if ((CompanyData.token ?? '').isNotEmpty)
          'Authorization': 'Bearer ${CompanyData.token}',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/tracking/day').replace(
        queryParameters: {
          'empid': empid,
          'dateIso': selectedDateIso,
        },
      );

      // Debug logs: request info
      debugPrint('[EMP_DETAIL] GET /tracking/day');

      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '[EMP_DETAIL] /tracking/day response status=${resp.statusCode}');

      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }

      final json = jsonDecode(resp.body);

      final data = (json is Map && json['data'] is Map)
          ? Map<String, dynamic>.from(json['data'])
          : <String, dynamic>{};

      // Debug: inspect events presence and content
      try {
        final ev = data['events'];
        if (ev == null) {
          // no events
        } else if (ev is List) {
          debugPrint('[EMP_DETAIL] events count=${ev.length}');
        } else {
          debugPrint('[EMP_DETAIL] events present but not a List');
        }
      } catch (e) {
        debugPrint('[EMP_DETAIL] events inspect error');
      }

      // Debug: inspect pathMap presence and content
      try {
        final pm = data['pathMap'];

        if (pm == null) {
          // no pathMap
        } else if (pm is List) {
          debugPrint('[EMP_DETAIL] pathMap count=${pm.length}');
        } else {
          debugPrint('[EMP_DETAIL] pathMap present but not a List');
        }
      } catch (e) {
        debugPrint('[EMP_DETAIL] pathMap inspect error');
      }

      _cachedTrackingDay = data;
      _trackingEvents = _getTrackingEvents(data);
      _trackingLoaded = true;
      _showTrackingEvents = true;

      _renderTrackingPath(data,
          fitCamera: fitCamera, notifyEmpty: !silent);
      _isLoadingPath = false;
      if (!silent) setState(() {});
    } catch (e) {
      _isLoadingPath = false;
      if (!silent) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geo load failed: $e')),
        );
      }
    }
  }

  /// 3) Branch Location — show attendance.expectedLat/Lng (lavender pin)
  void _showBranchOnMap() {
    if (expectedLat == null || expectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch coordinates not available from server.'),
        ),
      );
      return;
    }

    final pos = LatLng(expectedLat!, expectedLng!);

    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('branch'),
          position: pos,
          infoWindow: InfoWindow(title: 'Branch location', snippet: branchName),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );

    _polylines.clear();
    _animate(pos, 18);
    setState(() {});
  }

  void _animate(LatLng p, double z) {
    _initialCam = CameraPosition(target: p, zoom: z);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCam));
  }

  void _fitCameraToAll(List<LatLng> pts, {double padding = 48}) {
    if (_mapController == null || pts.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (final p in pts) {
      minLat = (minLat == null)
          ? p.latitude
          : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null)
          ? p.latitude
          : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null)
          ? p.longitude
          : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null)
          ? p.longitude
          : (p.longitude > maxLng ? p.longitude : maxLng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    _mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _mapController?.dispose();
    dateController.dispose();
    super.dispose();
  }

  // ---------------- UI helpers ----------------

  /// GPS tracking status card (Phase 2E): server-computed status, last
  /// successful update freshness, latest recorded location, and a
  /// suspicious-activity warning when flagged evidence exists. Hidden
  /// until the first tracking-day load finishes.
  Widget _buildTrackingStatusCard() {
    if (!_trackingLoaded || _cachedTrackingDay == null) {
      return const SizedBox.shrink();
    }
    final data = _cachedTrackingDay!;
    final tStatus = (data['trackingStatus'] ?? 'unknown').toString();
    final lastUpdate = _parseEventTs(data['lastUpdateAt']);
    // Separate freshness signals: last valid device fix vs last contact.
    // A stationary employee has a fresh fix but an old stored point.
    final lastGpsFix = _parseEventTs(
        data['lastGpsFixAt'] ?? data['lastLocationAt'] ?? data['lastUpdateAt']);
    final lastHeartbeat = _parseEventTs(data['lastHeartbeatAt']);

    final path = (data['pathMap'] is List) ? data['pathMap'] as List : [];
    Map<String, dynamic>? lastPt;
    for (var i = path.length - 1; i >= 0; i--) {
      final m = Map<String, dynamic>.from(path[i] as Map);
      if (_toDoubleOrNull(m['lat']) != null &&
          _toDoubleOrNull(m['lng']) != null) {
        lastPt = m;
        break;
      }
    }

    final hasSuspicious = _trackingEvents
        .any((e) => e['type']?.toString() == 'suspicious_location');

    final color = _trackingStatusColor(tStatus);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.my_location, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              trackingStatusLabel(tStatus),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
            const Spacer(),
            Text(
              trackingGpsFreshnessLabel(lastGpsFix ?? lastUpdate),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ]),
          // Contact line only when it adds information: the device is
          // alive but GPS is stale -> "alive but no fix", never offline.
          if (lastHeartbeat != null &&
              (lastGpsFix == null ||
                  lastHeartbeat.difference(lastGpsFix).inMinutes > 15)) ...[
            const SizedBox(height: 4),
            Text(
              trackingContactLabel(lastHeartbeat),
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
            ),
          ],
          if (lastPt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Latest location: '
              '${_toDoubleOrNull(lastPt['lat'])!.toStringAsFixed(5)}, '
              '${_toDoubleOrNull(lastPt['lng'])!.toStringAsFixed(5)}'
              '  ·  ${_fmtPointTime(lastPt['ts'])}',
              style:
                  const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
          if (hasSuspicious) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Text(
                'Suspicious location activity flagged for review. '
                'See Tracking Events for details.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtPointTime(dynamic tsRaw) {
    final ts = _parseEventTs(tsRaw);
    return ts == null ? '-' : _timeFmt.format(ts);
  }

  Color _trackingStatusColor(String status) {
    switch (status) {
      case 'healthy':
      case 'active':
        return Colors.green.shade700;
      case 'gps_delayed':
      case 'stale':
        return Colors.orange.shade800;
      case 'gps_unavailable':
      case 'gps_disabled':
      case 'permission_revoked':
      case 'interrupted':
        return Colors.red.shade700;
      case 'checked_out':
        return kButtonColor;
      default:
        return Colors.grey.shade600;
    }
  }

  String _fmt(String? v, {String dash = '-'}) =>
      (v == null || v.trim().isEmpty) ? dash : v;

  String _fmtNum(num? v) => (v == null) ? '-' : v.toString();

  String _fmtMeters(num? v) =>
      (v == null) ? '-' : '${v.toStringAsFixed(1)} m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        backgroundColor: kAdminAppBarColor,
        foregroundColor: kTextColor,
        title: Text('Employee ID: $empid'),
        actions: [
          if (!_loading && _error == null)
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        (name.isEmpty ? '-' : name),
                        style: const TextStyle(
                          fontSize: 18, // Changed from 20 to 18
                          fontWeight:
                              FontWeight.w600, // Changed from w700 to w600
                          color: kButtonColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Details
                      _DetailRow(label: 'Date', value: dateIso),
                      _DetailRow(label: 'Department', value: _fmt(department)),
                      _DetailRow(label: 'Shift', value: _fmt(shift)),
                      _DetailRow(label: 'Location', value: _fmt(branchName)),
                      _DetailRow(label: 'Check-in', value: _fmt(checkIn)),
                      _DetailRow(
                        label: 'Check-out',
                        value: _fmt(checkOut, dash: '—'),
                      ),
                      _DetailRow(label: 'Latitude', value: _fmtNum(checkInLat)),
                      _DetailRow(
                          label: 'Longitude', value: _fmtNum(checkInLng)),
                      _DetailRow(
                        label: 'Check-in GPS Accuracy',
                        value: _fmtMeters(checkInAccuracy),
                      ),
                      _DetailRow(
                        label: 'Distance from Office',
                        value: _fmtMeters(distanceFromBranch),
                      ),
                      _DetailRow(
                        label: 'Office Presence',
                        value:
                            _fmt(officePresenceLabel(officePresence)),
                      ),
                      if (checkOutLat != null || checkOutLng != null) ...[
                        _DetailRow(
                            label: 'Check-out Latitude',
                            value: _fmtNum(checkOutLat)),
                        _DetailRow(
                            label: 'Check-out Longitude',
                            value: _fmtNum(checkOutLng)),
                        _DetailRow(
                          label: 'Check-out GPS Accuracy',
                          value: _fmtMeters(checkOutAccuracy),
                        ),
                        _DetailRow(
                          label: 'Check-out Office Presence',
                          value: _fmt(officePresenceLabel(
                              checkOutOfficePresence)),
                        ),
                      ],
                      _DetailRow(label: 'Status', value: _fmt(status)),

                      const SizedBox(height: 12),
                      _buildTrackingStatusCard(),

                      const SizedBox(height: 16),

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
                          // Map type buttons
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

                      const SizedBox(height: 16),

                      // Row 1: Check-in Location + Geolocation
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showCheckInOnMap,
                              icon: const Icon(Icons.login),
                              label: const Text('Check-in Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showLastTrackingPath,
                              icon: const Icon(Icons.alt_route),
                              label: const Text('Geolocation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row 2: Branch Location (full width)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showBranchOnMap,
                          icon: const Icon(Icons.place),
                          label: const Text('Branch Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C6EAF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Google Map
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black12),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: _initialCam,
                                // ✨ Enable smooth interactivity
                                zoomControlsEnabled: true,
                                myLocationButtonEnabled: true,
                                mapToolbarEnabled: true,
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                rotateGesturesEnabled: true,
                                tiltGesturesEnabled: true,

                                // 👇 This is the key so gestures win over the ListView
                                gestureRecognizers: <Factory<
                                    OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },

                                myLocationEnabled: false,
                                markers: _markers,
                                polylines: _polylines,
                                onMapCreated: (c) {
                                  _mapController = c;
                                  if (checkInLat != null &&
                                      checkInLng != null) {
                                    _mapController!.moveCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(checkInLat!, checkInLng!),
                                        18,
                                      ),
                                    );
                                  }
                                },
                                mapType: _mapType,
                              ),
                              if (_isLoadingPath)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildTrackingEventsSection(),
                      const SizedBox(height: 16),
                      const Text(
                        'Open Shift Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ShiftLogRow(
                        entryLabel: 'Entry',
                        entryValue: _fmt(checkIn),
                        exitLabel: 'Exit',
                        exitValue: _fmt(checkOut, dash: 'null'),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _dateIso() {
    final d = selectedDate ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(), // Don't allow future dates
    );

    if (picked != null) {
      final formattedDisplayDate = "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";

      setState(() {
        selectedDate = picked;
        dateController.text = formattedDisplayDate;
        // Clear cached tracking when date changes
        _cachedTrackingDay = null;
        _trackingLoaded = false;
        _showTrackingEvents = false;
        _trackingEvents = [];
        // Clear map markers and polylines
        _markers.clear();
        _polylines.clear();
      });

      // Reload tracking for new date
      await _showLastTrackingPath();
    }
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
          Expanded(
            child: Text(
              '$exitLabel: $exitValue',
              textAlign: TextAlign.right,
            ),
          ),
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
