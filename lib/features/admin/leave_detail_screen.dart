import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:serv_app/services/api_service.dart';

final String apiBase = ApiService.baseUrl;

// ── Colour tokens ──────────────────────────────────────────────────────────────
const Color kAppBarBg          = Color(0xFF6A1B9A);
const Color kBtnPrimary        = Color(0xFF7C5FA0);
const Color kBtnBranch         = Color(0xFF5B9C7A);
const Color kBtnReject         = Color(0xFFE35D6A);
const Color kBtnApprove        = Color(0xFF87A963);
const Color kPageBg            = Color(0xFFF4F1F8);
const Color kCardBg            = Colors.white;
const Color kFieldBg           = Color(0xFFF5F2F9);
const Color kFieldBorder       = Color(0xFFEAE4F2);
const Color kLabelColor        = Color(0xFF9E96AE);
const Color kValueColor        = Color(0xFF1F1A2B);
const Color kTitleColor        = Color(0xFF1F1A2B);
const Color kBadgeYesBg        = Color(0xFFEAF3DE);
const Color kBadgeYesText      = Color(0xFF3B6D11);
const Color kBadgeNoBg         = Color(0xFFFCEBEB);
const Color kBadgeNoText       = Color(0xFFA32D2D);
const Color kMapLegendReq      = Color(0xFFE53935);
const Color kMapLegendBranch   = Color(0xFF43A047);

const double kDefaultRadiusMeters = 100;

class RequestDetailsCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const RequestDetailsCard({super.key, required this.data});

  @override
  State<RequestDetailsCard> createState() => _RequestDetailsCardState();
}

class _RequestDetailsCardState extends State<RequestDetailsCard> {
  final Completer<GoogleMapController> _mapCtrl =
      Completer<GoogleMapController>();
  LatLng? _pendingTarget;
  String? _pendingMarkerId;

  late Map<String, dynamic> _data;
  bool _loadingDetails = false;
  String? _loadError;

  /* ── tolerant getters ──────────────────────────────────────────────────────── */

  double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString().trim());

  bool? _toBool(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
    return null;
  }

  String _pickStr(List<String> keys) {
    for (final k in keys) {
      final v = _data[k] ?? _data[k.toLowerCase()] ?? _data[k.toUpperCase()];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  double? _pickNum(List<String> keys) {
    for (final k in keys) {
      final v = _data[k] ?? _data[k.toLowerCase()] ?? _data[k.toUpperCase()];
      final d = _toDouble(v);
      if (d != null) return d;
    }
    return null;
  }

  /* ── lat/lng helpers ───────────────────────────────────────────────────────── */

  LatLng? _parseLatLngString(String s) {
    final parts =
        s.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).toList();
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? _latLngFromMap(Map m) {
    double? lat = _toDouble(
      m['latitude'] ?? m['lat'] ?? m['Latitude'] ?? m['Lat'] ??
          m['branchLat'] ?? m['branch_latitude'],
    );
    double? lng = _toDouble(
      m['longitude'] ?? m['lng'] ?? m['lon'] ?? m['Longitude'] ??
          m['Lng'] ?? m['branchLng'] ?? m['branch_longitude'],
    );
    if (lat != null && lng != null) return LatLng(lat, lng);
    try {
      final lat2 = _toDouble(m['geo']?['lat'] ?? m['coords']?['lat']);
      final lng2 = _toDouble(m['geo']?['lng'] ?? m['coords']?['lng']);
      if (lat2 != null && lng2 != null) return LatLng(lat2, lng2);
    } catch (_) {}
    final locStr = m['location']?.toString();
    if (locStr != null && locStr.contains(',')) {
      final ll = _parseLatLngString(locStr);
      if (ll != null) return ll;
    }
    return null;
  }

  LatLng? _latLngFrom(dynamic any) {
    if (any == null) return null;
    if (any is LatLng) return any;
    if (any is Map) return _latLngFromMap(any);
    if (any is String) return _parseLatLngString(any);
    try {
      final lat = _toDouble(any.latitude);
      final lng = _toDouble(any.longitude);
      if (lat != null && lng != null) return LatLng(lat, lng);
    } catch (_) {}
    return null;
  }

  LatLng? _findRequestLatLng() {
    double? lat =
        _pickNum(['latitude', 'lat', 'requestLatitude', 'requestedLatitude']);
    double? lng = _pickNum(
        ['longitude', 'lng', 'lon', 'requestLongitude', 'requestedLongitude']);
    if (lat != null && lng != null) return LatLng(lat, lng);
    for (final key in [
      'otherLocation', 'requestLocation', 'locationObj',
      'requestedLocation', 'geo', 'coords'
    ]) {
      final ll = _latLngFrom(_data[key]);
      if (ll != null) return ll;
    }
    for (final key in ['location', 'otherLocation']) {
      final s = _data[key]?.toString();
      if (s != null) {
        final ll = _parseLatLngString(s);
        if (ll != null) return ll;
      }
    }
    lat ??= _pickNum(['checkInLatitude', 'check_in_latitude']);
    lng ??= _pickNum(['checkInLongitude', 'check_in_longitude']);
    if (lat != null && lng != null) return LatLng(lat, lng);
    lat ??= _pickNum(['checkOutLatitude', 'check_out_latitude']);
    lng ??= _pickNum(['checkOutLongitude', 'check_out_longitude']);
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  LatLng? _findBranchCenter() {
    double? lat = _pickNum([
      'expectedLatitude', 'branchLatitude', 'officeLatitude',
      'expected_latitude', 'branchLat', 'branch_latitude',
    ]);
    double? lng = _pickNum([
      'expectedLongitude', 'branchLongitude', 'officeLongitude',
      'expected_longitude', 'branchLng', 'branch_longitude',
    ]);
    if (lat != null && lng != null) return LatLng(lat, lng);
    for (final key in [
      'branch', 'expected', 'expectedLocation', 'office',
      'branchCenter', 'branchLocationObj'
    ]) {
      final ll = _latLngFrom(_data[key]);
      if (ll != null) return ll;
    }
    for (final key in ['branchLocation', 'expectedLocation']) {
      final s = _data[key]?.toString();
      if (s != null) {
        final ll = _parseLatLngString(s);
        if (ll != null) return ll;
      }
    }
    return null;
  }

  /* ── misc helpers ──────────────────────────────────────────────────────────── */

  double _haversineMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  String _withinRadiusText({
    required LatLng? req,
    required LatLng? center,
    required double? expectedRadius,
    required double? distanceFromBranch,
    required bool? withinFlag,
  }) {
    if (withinFlag != null) return withinFlag ? 'Yes' : 'No';
    if (distanceFromBranch != null && expectedRadius != null) {
      return distanceFromBranch <= expectedRadius ? 'Yes' : 'No';
    }
    if (req != null && center != null && expectedRadius != null) {
      return _haversineMeters(req, center) <= expectedRadius ? 'Yes' : 'No';
    }
    if (req != null && center != null) {
      return _haversineMeters(req, center) <= kDefaultRadiusMeters
          ? 'Yes'
          : 'No';
    }
    return '-';
  }

  Future<void> _focusOn(LatLng target,
      {double zoom = 17, String? markerId}) async {
    if (!_mapCtrl.isCompleted) {
      _pendingTarget = target;
      _pendingMarkerId = markerId;
      return;
    }
    final c = await _mapCtrl.future;
    final cam = CameraPosition(target: target, zoom: zoom);
    try {
      await c.animateCamera(CameraUpdate.newCameraPosition(cam));
    } catch (_) {
      await c.moveCamera(CameraUpdate.newCameraPosition(cam));
    }
    if (markerId != null) {
      await Future.delayed(const Duration(milliseconds: 60));
      try {
        await c.showMarkerInfoWindow(MarkerId(markerId));
      } catch (_) {}
    }
  }

  /* ── API ───────────────────────────────────────────────────────────────────── */

  String _inferSrc(Map<String, dynamic> m) {
    final s = (m['source'] ?? m['src'] ?? '').toString().toLowerCase();
    if (s == 'attendance' || s == 'other_location') return s;
    final t = (m['type'] ?? m['category'] ?? '').toString().toLowerCase();
    if (t.contains('other') && t.contains('location')) return 'other_location';
    if (t.contains('late') || t.contains('early')) return 'attendance';
    if (m.containsKey('withinRadius') ||
        m.containsKey('expectedLatitude') ||
        m.containsKey('otherLocation')) {
      return 'other_location';
    }
    return 'attendance';
  }

  Future<void> _fetchAndMergeDetails() async {
    String id = (_data['id'] ?? _data['requestId'] ?? _data['docId'] ??
            _data['attendanceId'] ?? _data['otherLocId'])
        ?.toString() ?? '';
    String empid =
        (_data['empid'] ?? _data['empId'] ?? _data['employeeId'])
            ?.toString() ?? '';
    String date =
        (_data['requestDate'] ?? _data['date'] ?? _data['onDate'])
            ?.toString() ?? '';
    if (date.length > 10) date = date.substring(0, 10);
    final src = _inferSrc(_data);

    if (id.isEmpty && (empid.isEmpty || date.isEmpty)) return;

    setState(() {
      _loadingDetails = true;
      _loadError = null;
    });

    try {
      final qp = <String, String>{
        if (id.isNotEmpty) 'id': id,
        if (id.isNotEmpty) 'src': src,
        if (id.isEmpty && empid.isNotEmpty) 'empid': empid,
        if (id.isEmpty && date.isNotEmpty) 'date': date,
      };

      final res = await ApiService.get(
        '/attendance/request-details',
        query: qp,
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        setState(() => _data = {..._data, ...body});
      }
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
    unawaited(_fetchAndMergeDetails());
  }

  /* ── BUILD ─────────────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final empId     = _pickStr(['empid', 'employeeId', 'id', 'EmpID']);
    final name      = _pickStr(['name', 'employeeName']);
    final requestType = _pickStr(['type', 'category']);
    final requestTime = _pickStr([
      'requestTime', 'time', 'createdAt', 'updatedAt',
      'checkInTime', 'checkOutTime'
    ]);
    final requestDate = _pickStr([
      'requestDate', 'date', 'onDate', 'startDate', 'selectDate'
    ]);
    final branchName    = _pickStr(['branchName', 'branchLocation', 'location']);
    final freeTextReason = _pickStr(['reason', 'otherLocation', 'note', 'remarks']);
    final rejectionRemarks = _pickStr(['rejectionRemarks']);

    final reqLL     = _findRequestLatLng();
    final centerLL  = _findBranchCenter();
    final expectedRadius = _pickNum(['expectedRadius', 'radius']);
    final distanceFromBranch =
        _pickNum(['distanceFromBranch', 'distance_from_branch', 'distance']);
    final withinRadiusFlag = _toBool(
      _data['withinRadius'] ?? _data['within_radius'] ??
          _data['isWithinRadius'] ?? _data['insideRadius'] ??
          _data['within'] ?? _data['inRadius'],
    );

    final withinText = _withinRadiusText(
      req: reqLL, center: centerLL,
      expectedRadius: expectedRadius,
      distanceFromBranch: distanceFromBranch,
      withinFlag: withinRadiusFlag,
    );

    final distanceText = distanceFromBranch != null
        ? distanceFromBranch.toStringAsFixed(0)
        : '-';

    final LatLng initialTarget =
        reqLL ?? centerLL ?? const LatLng(20.5937, 78.9629);
    final double initialZoom =
        (reqLL != null || centerLL != null) ? 17 : 4;

    final Set<Marker> markers = {
      if (reqLL != null)
        Marker(
          markerId: const MarkerId('request'),
          position: reqLL,
          infoWindow: const InfoWindow(title: 'Requested location'),
        ),
      if (centerLL != null)
        Marker(
          markerId: const MarkerId('branch'),
          position: centerLL,
          infoWindow: InfoWindow(
            title: branchName.isNotEmpty ? branchName : 'Branch location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ),
    };

    final Set<Circle> circles = {
      if (centerLL != null && expectedRadius != null)
        Circle(
          circleId: const CircleId('geofence'),
          center: centerLL,
          radius: expectedRadius,
          strokeWidth: 2,
          strokeColor: const Color(0x8032CD32),
          fillColor: const Color(0x3032CD32),
        ),
    };

    return Scaffold(
      backgroundColor: kPageBg,
      // ── App bar ──────────────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: AppBar(
          backgroundColor: kAppBarBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Request Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Employee ID: ${empId.isEmpty ? '—' : empId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loadError != null
          ? _buildError()
          : Column(
              children: [
                // slim progress bar
                if (_loadingDetails)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: kAppBarBg,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    child: Column(
                      children: [
                        // ── Employee ──────────────────────────────────────────
                        _card(
                          title: 'EMPLOYEE',
                          child: _fieldGrid([
                            _field('Name', name),
                            _field('Request type', requestType),
                            _field('Requested time', requestTime),
                            _field('Request date', requestDate),
                          ]),
                        ),
                                                const SizedBox(height: 10),
                        // ── Location ──────────────────────────────────────────
                        _card(
                          title: 'LOCATION',
                          child: Column(
                            children: [
                              // focus buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _locationButton(
                                      label: 'Requested',
                                      icon: Icons.my_location_rounded,
                                      color: kBtnPrimary,
                                      onPressed: reqLL != null
                                          ? () => _focusOn(reqLL,
                                                markerId: 'request')
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _locationButton(
                                      label: 'Branch',
                                      icon: Icons.home_work_rounded,
                                      color: kBtnBranch,
                                      onPressed: centerLL != null
                                          ? () => _focusOn(centerLL,
                                                markerId: 'branch')
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // within-radius + distance badges
                              Row(
                                children: [
                                  Expanded(
                                    child: _radiusBadge(
                                      label: 'Within radius',
                                      value: withinText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _field(
                                      'Distance from branch (m)',
                                      distanceText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ── Map ───────────────────────────────────────────────
                        _mapCard(
                          initialTarget: initialTarget,
                          initialZoom: initialZoom,
                          markers: markers,
                          circles: circles,
                          branchName: branchName,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // ── Footer buttons ────────────────────────────────────────────
                _footer(context),
              ],
            ),
    );
  }

  /* ── Error view ──────────────────────────────────────────────────────────── */

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD8D8)),
            ),
            child: Text(
              'Error: $_loadError',
              style: const TextStyle(
                  color: kBtnReject, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  /* ── Section card ────────────────────────────────────────────────────────── */

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kLabelColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /* ── Field grid ─────────────────────────────────────────────────────────── */

  Widget _fieldGrid(List<Widget> children) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final isLast = i + 1 >= children.length;
      rows.add(
        Row(
          children: [
            Expanded(child: children[i]),
            if (!isLast) ...[
              const SizedBox(width: 8),
              Expanded(child: children[i + 1]),
            ],
          ],
        ),
      );
      if (i + 2 < children.length) const SizedBox(height: 8);
    }
    return Column(
      children: rows
          .expand((w) => [w, const SizedBox(height: 8)])
          .toList()
        ..removeLast(),
    );
  }

  /* ── Single field chip ───────────────────────────────────────────────────── */

  Widget _field(String label, String value, {bool fullWidth = false}) {
    final chip = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kFieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: kLabelColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kValueColor,
            ),
          ),
        ],
      ),
    );
    return fullWidth ? Row(children: [Expanded(child: chip)]) : chip;
  }

  /* ── Within-radius coloured badge ───────────────────────────────────────── */

  Widget _radiusBadge({required String label, required String value}) {
    final isYes = value == 'Yes';
    final isDash = value == '-';
    final bg   = isDash ? kFieldBg  : (isYes ? kBadgeYesBg  : kBadgeNoBg);
    final fg   = isDash ? kValueColor : (isYes ? kBadgeYesText : kBadgeNoText);
    final borderColor = isDash ? kFieldBorder
        : (isYes ? const Color(0xFFC5E2A0) : const Color(0xFFF5C0C0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: kLabelColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  /* ── Location focus button ───────────────────────────────────────────────── */

  Widget _locationButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.3),
          disabledForegroundColor: Colors.white60,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  /* ── Map card ────────────────────────────────────────────────────────────── */

  Widget _mapCard({
    required LatLng initialTarget,
    required double initialZoom,
    required Set<Marker> markers,
    required Set<Circle> circles,
    required String branchName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'MAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kLabelColor,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: GoogleMap(
                    onMapCreated: (c) async {
                      if (!_mapCtrl.isCompleted) _mapCtrl.complete(c);
                      if (_pendingTarget != null) {
                        final t  = _pendingTarget!;
                        final id = _pendingMarkerId;
                        _pendingTarget = null;
                        _pendingMarkerId = null;
                        await Future.microtask(
                            () => _focusOn(t, markerId: id));
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: initialZoom,
                    ),
                    markers: markers,
                    circles: circles,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                  ),
                ),
                // legend strip
                Container(
                  color: kCardBg,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      _legendDot(kMapLegendReq, 'Requested location'),
                      const SizedBox(width: 16),
                      _legendDot(kMapLegendBranch, 'Branch location'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kLabelColor),
          ),
        ],
      );

  /* ── Footer ──────────────────────────────────────────────────────────────── */

  Widget _footer(BuildContext context) {
    return Container(
      color: kPageBg,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kBtnPrimary,
                  side: const BorderSide(color: kBtnPrimary, width: 0.5),
                  backgroundColor: kCardBg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, 'rejected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBtnReject,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, 'approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBtnApprove,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Approve',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}