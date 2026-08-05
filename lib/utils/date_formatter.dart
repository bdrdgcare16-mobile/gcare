import 'package:intl/intl.dart';

/// Parses a payroll date from various Firestore timestamp formats.
/// Supports:
/// - Firestore serialized map: {_seconds: 123, _nanoseconds: 456}
/// - Alternate serialized map: {seconds: 123, nanoseconds: 456}
/// - ISO date string: "2026-08-05T09:17:18.577Z"
/// - Millisecond timestamp (number)
/// - DateTime object
DateTime? parsePayrollDate(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is Map) {
    final seconds =
        value['_seconds'] ??
        value['seconds'];

    final nanoseconds =
        value['_nanoseconds'] ??
        value['nanoseconds'] ??
        0;

    if (seconds is num) {
      final milliseconds =
          (seconds * 1000).round() +
          ((nanoseconds is num ? nanoseconds : 0) / 1000000).round();

      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }
  }

  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
      isUtc: true,
    ).toLocal();
  }

  final raw = value.toString().trim();

  if (raw.isEmpty) return null;

  return DateTime.tryParse(raw)?.toLocal();
}

/// Formats a DateTime to the standard payroll date format.
/// Format: dd MMM yyyy, hh:mm a
/// Example: 05 Aug 2026, 02:47 PM
String formatPayrollDate(DateTime? dateTime) {
  if (dateTime == null) return 'Not available';

  return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
}

/// Parses and formats a payroll date in one step.
String formatPayrollDateFromDynamic(dynamic value) {
  final dateTime = parsePayrollDate(value);
  return formatPayrollDate(dateTime);
}
