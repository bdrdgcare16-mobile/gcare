import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/tracking_post_result.dart';

TrackingPostResult _parse(int code, Object body) =>
    TrackingPostResult.fromResponse(http.Response(jsonEncode(body), code));

void main() {
  group('TrackingPostResult - new backend schema', () {
    test('appended is persisted and sets marker', () {
      final r = _parse(200, {'status': 'appended', 'pathMapCount': 1});
      expect(r.persisted, isTrue);
      expect(r.recentPointExists, isTrue);
      expect(r.pathMapCount, 1);
    });

    test('duplicate pointId counts as persisted (idempotent retry)', () {
      final r = _parse(200, {'status': 'duplicate', 'pathMapCount': 1});
      expect(r.persisted, isTrue);
    });

    test('time_throttled: 200 but not persisted; recent point exists', () {
      final r = _parse(200, {'status': 'time_throttled', 'pathMapCount': 3});
      expect(r.httpOk, isTrue);
      expect(r.persisted, isFalse);
      expect(r.recentPointExists, isTrue);
    });

    test('too_close and session_ended never set the marker', () {
      for (final s in ['too_close', 'session_ended']) {
        final r = _parse(200, {'status': s});
        expect(r.persisted, isFalse, reason: s);
        expect(r.recentPointExists, isFalse, reason: s);
      }
    });

    test('sessionEnded is true only for the session_ended status', () {
      expect(_parse(200, {'status': 'session_ended'}).sessionEnded, isTrue);
      for (final s in ['appended', 'duplicate', 'time_throttled', 'too_close']) {
        expect(_parse(200, {'status': s}).sessionEnded, isFalse, reason: s);
      }
      expect(
          TrackingPostResult.fromResponse(http.Response('x', 500)).sessionEnded,
          isFalse);
    });

    test('legacy "Tracking session already ended" maps to sessionEnded', () {
      final r = _parse(
          200, {'added': null, 'reason': 'Tracking session already ended'});
      expect(r.sessionEnded, isTrue);
    });
  });

  group('TrackingPostResult - legacy backend schema', () {
    test('added != null => appended', () {
      final r = _parse(200, {'added': {'lat': 1, 'lng': 2}, 'throttled': false});
      expect(r.status, 'appended');
    });

    test('throttled reasons are mapped', () {
      expect(
          _parse(200, {'added': null, 'reason': 'Time throttled - only 1.0min'})
              .status,
          'time_throttled');
      expect(
          _parse(200, {'added': null, 'reason': 'Movement too small - only 2m'})
              .status,
          'too_close');
      expect(
          _parse(200, {'added': null, 'reason': 'Tracking session already ended'})
              .status,
          'session_ended');
    });
  });

  group('TrackingPostResult - failures', () {
    test('5xx is retryable, 4xx is not, neither persisted', () {
      final s = _parse(503, {'error': 'x'});
      final c = _parse(400, {'error': 'x'});
      expect(s.retryable, isTrue);
      expect(c.retryable, isFalse);
      expect(s.persisted || c.persisted, isFalse);
    });

    test('unparseable 200 body is not treated as persisted', () {
      final r = TrackingPostResult.fromResponse(http.Response('ok', 200));
      expect(r.status, 'unknown');
      expect(r.recentPointExists, isFalse);
    });
  });

  test('trackingDateIso uses local calendar date', () {
    expect(trackingDateIso(DateTime(2026, 10, 12, 0, 30)), '2026-10-12');
    expect(trackingDateIso(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
  });
}
