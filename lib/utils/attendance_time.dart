bool attendanceAutoInactive(Map<String, dynamic> record, [DateTime? now]) {
  if (record['sessionState'] == 'auto_inactive') return true;
  if (record['sessionState'] != 'active' || record['checkOut'] != null ||
      record['checkOutTsUtc'] != null) {
    return false;
  }
  final deadline = DateTime.tryParse(record['expiresAt']?.toString() ?? '');
  final serverNow = DateTime.tryParse(record['serverNowUtc']?.toString() ?? '');
  return deadline != null && !(now ?? serverNow ?? DateTime.now()).isBefore(deadline);
}

DateTime attendanceWallTime([DateTime? instant]) =>
    (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));

DateTime? parseAttendanceTime(dynamic timestamp, String? hms, String? date) {
  final utc = DateTime.tryParse(timestamp?.toString() ?? '');
  if (utc != null) return attendanceWallTime(utc);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date ?? '') ||
      !RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$').hasMatch(hms ?? '')) {
    return null;
  }
  final time = hms!.length == 5 ? '$hms:00' : hms;
  final result = DateTime.tryParse('${date}T${time}Z');
  if (result == null || result.toIso8601String().substring(0, 10) != date) {
    return null;
  }
  return result;
}
