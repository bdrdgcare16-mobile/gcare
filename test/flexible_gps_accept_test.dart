import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the flexible-accept timer logic added to
/// `_getHighAccuracyPosition` in `attendance_page.dart`'s stream phase:
/// a precise fix (<=maxAccuracyMeters) is always accepted the instant it
/// arrives; otherwise, once `flexibleAcceptAfter` elapses, whatever
/// non-mocked fresh fix has been seen so far is accepted instead of
/// waiting out the full `overallTimeout`. No fix at all before the grace
/// window means no early accept - the full timeout still applies.
///
/// This is implemented standalone (not by invoking the private State
/// method, which isn't reachable from a unit test) so the acceptance
/// *decision* can be verified deterministically and fast via FakeAsync,
/// following this repo's existing dispose_probe_test.dart pattern of
/// mirroring fixed logic rather than driving the full widget.
class _FixSample {
  final double accuracy;
  const _FixSample(this.accuracy);
}

class _AcceptanceResult {
  final _FixSample? position;
  final String reason; // 'precise' | 'flexible' | 'timeout' | 'no_fix'
  const _AcceptanceResult(this.position, this.reason);
}

Future<_AcceptanceResult> _runAcquisition({
  required Duration overallTimeout,
  required Duration flexibleAcceptAfter,
  required double maxAccuracyMeters,
  required List<(Duration, _FixSample)> fixesAtOffsets,
}) async {
  _FixSample? bestPosition;
  bool acquisitionComplete = false;
  String reason = 'timeout';
  final completer = Completer<_FixSample?>();

  final timeoutTimer = Timer(overallTimeout, () {
    if (!acquisitionComplete && !completer.isCompleted) {
      completer.complete(bestPosition);
    }
  });

  Timer? flexibleTimer;
  if (overallTimeout > flexibleAcceptAfter) {
    flexibleTimer = Timer(flexibleAcceptAfter, () {
      if (acquisitionComplete || completer.isCompleted) return;
      if (bestPosition == null) return;
      reason = 'flexible';
      acquisitionComplete = true;
      timeoutTimer.cancel();
      completer.complete(bestPosition);
    });
  }

  for (final (offset, fix) in fixesAtOffsets) {
    Timer(offset, () {
      if (acquisitionComplete || completer.isCompleted) return;
      if (bestPosition == null || fix.accuracy < bestPosition!.accuracy) {
        bestPosition = fix;
      }
      if (fix.accuracy <= maxAccuracyMeters) {
        reason = 'precise';
        acquisitionComplete = true;
        timeoutTimer.cancel();
        flexibleTimer?.cancel();
        completer.complete(fix);
      }
    });
  }

  // Elapsing is driven by the caller (via the `fakeAsync` passed in), so
  // tests can inspect intermediate state before the completer resolves.
  final result = await completer.future;
  timeoutTimer.cancel();
  flexibleTimer?.cancel();
  if (result == null) reason = 'no_fix';
  return _AcceptanceResult(result, reason);
}

void main() {
  group('flexible GPS accept timer', () {
    test('precise fix arriving immediately is accepted instantly, '
        'not delayed by the flexible grace window', () {
      fakeAsync((fakeAsync) {
        _AcceptanceResult? result;
        unawaited(_runAcquisition(
          overallTimeout: const Duration(seconds: 60),
          flexibleAcceptAfter: const Duration(seconds: 15),
          maxAccuracyMeters: 50,
          fixesAtOffsets: [(const Duration(seconds: 2), const _FixSample(30))],
        ).then((r) => result = r));

        fakeAsync.elapse(const Duration(seconds: 3));
        expect(result!.reason, 'precise');
        expect(result!.position!.accuracy, 30);
      });
    });

    test('degraded fix is accepted after the flexible grace window, '
        'not after the full overall timeout', () {
      fakeAsync((fakeAsync) {
        _AcceptanceResult? result;
        unawaited(_runAcquisition(
          overallTimeout: const Duration(seconds: 60),
          flexibleAcceptAfter: const Duration(seconds: 15),
          maxAccuracyMeters: 50,
          fixesAtOffsets: [
            (const Duration(seconds: 2), const _FixSample(200)),
          ],
        ).then((r) => result = r));

        // Just before the grace window: nothing accepted yet.
        fakeAsync.elapse(const Duration(seconds: 14));
        expect(result, isNull);

        // Grace window elapses: the degraded (200m) fix is accepted
        // without waiting anywhere near the 60s overallTimeout.
        fakeAsync.elapse(const Duration(seconds: 2));
        expect(result!.reason, 'flexible');
        expect(result!.position!.accuracy, 200);
      });
    });

    test('a better fix arriving before the grace window wins and the '
        'flexible timer is cancelled (no stray late completion)', () {
      fakeAsync((fakeAsync) {
        _AcceptanceResult? result;
        unawaited(_runAcquisition(
          overallTimeout: const Duration(seconds: 60),
          flexibleAcceptAfter: const Duration(seconds: 15),
          maxAccuracyMeters: 50,
          fixesAtOffsets: [
            (const Duration(seconds: 5), const _FixSample(40)), // precise
          ],
        ).then((r) => result = r));

        fakeAsync.elapse(const Duration(seconds: 6));
        expect(result!.reason, 'precise');
        expect(result!.position!.accuracy, 40);

        // Advancing well past the grace window must not change the
        // already-resolved result.
        fakeAsync.elapse(const Duration(seconds: 60));
        expect(result!.reason, 'precise');
      });
    });

    test('no fix at all before the grace window still waits for the full '
        'overallTimeout - freshness/no-fix behavior is unchanged', () {
      fakeAsync((fakeAsync) {
        _AcceptanceResult? result;
        unawaited(_runAcquisition(
          overallTimeout: const Duration(seconds: 60),
          flexibleAcceptAfter: const Duration(seconds: 15),
          maxAccuracyMeters: 50,
          fixesAtOffsets: const [],
        ).then((r) => result = r));

        fakeAsync.elapse(const Duration(seconds: 16));
        expect(result, isNull, reason: 'no candidate fix exists yet');

        fakeAsync.elapse(const Duration(seconds: 60));
        expect(result!.reason, 'no_fix');
        expect(result!.position, isNull);
      });
    });

    test('flexibleAcceptAfter >= overallTimeout disables the flexible '
        'path entirely (falls back to the single full-timeout behavior)',
        () {
      fakeAsync((fakeAsync) {
        _AcceptanceResult? result;
        unawaited(_runAcquisition(
          overallTimeout: const Duration(seconds: 10),
          flexibleAcceptAfter: const Duration(seconds: 15),
          maxAccuracyMeters: 50,
          fixesAtOffsets: [
            (const Duration(seconds: 2), const _FixSample(200)),
          ],
        ).then((r) => result = r));

        fakeAsync.elapse(const Duration(seconds: 11));
        expect(result!.reason, 'timeout');
        expect(result!.position!.accuracy, 200);
      });
    });
  });
}
