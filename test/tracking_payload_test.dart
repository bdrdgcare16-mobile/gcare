import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:serv_app/services/tracking_payload.dart';

Position _pos({bool mocked = false, DateTime? at}) => Position(
      longitude: 77.0,
      latitude: 12.0,
      timestamp: at ?? DateTime.now(),
      accuracy: 8.5,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: mocked,
    );

void main() {
  group('buildTrackingPointPayload', () {
    test('propagates mocked + capturedAtUtc for server-side spoof checks', () {
      final p = buildTrackingPointPayloadFromPosition(
        empid: 'EMP1',
        position: _pos(mocked: true),
        source: 'fg/worker',
      );
      expect(p['mocked'], isTrue);
      // UTC ISO with Z suffix - the field the server trusts.
      expect((p['capturedAtUtc'] as String).endsWith('Z'), isTrue);
      expect(p['dateIso'], isNotNull);
      expect(p['empid'], 'EMP1');
    });

    test('non-mocked positions carry mocked=false explicitly', () {
      final p = buildTrackingPointPayloadFromPosition(
        empid: 'EMP1',
        position: _pos(),
        source: 'checkin-seed',
      );
      expect(p['mocked'], isFalse);
    });
  });

  group('offline queue persistence of suspicious metadata', () {
    test('encode/decode round-trip preserves mocked flag and accuracy', () {
      final payload = buildTrackingPointPayloadFromPosition(
        empid: 'EMP1',
        position: _pos(mocked: true),
        source: 'fg/worker',
      );
      final decoded = decodePendingLocation(encodePendingLocation(payload));
      expect(decoded, isNotNull);
      expect(decoded!['mocked'], isTrue);
      expect(decoded['accuracy'], 8.5);
      expect(decoded['capturedAtUtc'], payload['capturedAtUtc']);
    });

    test('corrupted queue entries decode to null (dropped safely)', () {
      expect(decodePendingLocation('not-json{'), isNull);
      expect(decodePendingLocation(jsonEncode([1, 2, 3])), isNull);
      expect(decodePendingLocation(jsonEncode('str')), isNull);
    });

    test('signature ignores mocked - same fix still dedupes', () {
      final a = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.0, lng: 77.0,
        accuracy: 8, mocked: false, source: 'fg/worker',
        capturedAt: DateTime.utc(2026, 10, 12, 8, 0),
      );
      final b = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.0, lng: 77.0,
        accuracy: 8, mocked: true, source: 'fg/worker',
        capturedAt: DateTime.utc(2026, 10, 12, 8, 0),
      );
      // Same capture, different flag value - still the same queue entry.
      expect(trackingPayloadSignature(a), trackingPayloadSignature(b));
    });

    test('signature dedupes one fix across producers via pointId', () {
      final at = DateTime.utc(2026, 10, 15, 14, 5, 58);
      final a = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.0, lng: 77.0, mocked: false,
        source: 'fg/worker', capturedAt: at,
        pointId: trackingPointIdFor(at),
      );
      // Same fix re-built by a different producer (different source) -
      // identical pointId means ONE queue entry, one upload.
      final b = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.0, lng: 77.0, mocked: true,
        source: 'checkin-seed', capturedAt: at,
        pointId: trackingPointIdFor(at),
      );
      expect(trackingPayloadSignature(a), trackingPayloadSignature(b));
    });

    test('trackingPointIdFor is producer-independent and deterministic',
        () {
      final at = DateTime.utc(2026, 10, 15, 14, 5, 58, 893);
      expect(trackingPointIdFor(at), 'pt-${at.millisecondsSinceEpoch}');
      // Same instant, different local timezone representation -> same id.
      expect(trackingPointIdFor(at.toLocal()), trackingPointIdFor(at));
    });

    test('signature differs for genuinely different captures', () {
      final a = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.0, lng: 77.0,
        mocked: false, source: 'fg/worker',
        capturedAt: DateTime.utc(2026, 10, 12, 8, 0),
      );
      final b = buildTrackingPointPayload(
        empid: 'EMP1', lat: 12.5, lng: 77.0,
        mocked: false, source: 'fg/worker',
        capturedAt: DateTime.utc(2026, 10, 12, 8, 0),
      );
      expect(trackingPayloadSignature(a), isNot(trackingPayloadSignature(b)));
    });
  });
}
