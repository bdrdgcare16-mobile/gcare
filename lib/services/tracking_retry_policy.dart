/// Bounded retry policy for tracking-session initialization after a
/// confirmed check-in. Extracted so the schedule is unit-testable without
/// instantiating the attendance page.
///
/// One short sequence of timed retries (5s/15s/45s) covers transient
/// failures; a permanently offline device is handled separately by the
/// connectivity-triggered recovery listener, not by burning attempts.
const int kMaxTrackingInitAttempts = 3;

const List<Duration> kTrackingInitRetryBackoffs = <Duration>[
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 45),
];

/// Delay before attempt [failedAttempts] + 1, or null once the bounded
/// schedule is exhausted - callers must then wait for connectivity restore
/// instead of retrying forever.
Duration? trackingInitRetryDelay(int failedAttempts) =>
    failedAttempts >= kMaxTrackingInitAttempts
        ? null
        : kTrackingInitRetryBackoffs[failedAttempts];
