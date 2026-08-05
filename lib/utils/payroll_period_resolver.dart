import 'package:intl/intl.dart';

class PayrollPeriod {
  final int month;
  final int year;
  final String monthName;

  const PayrollPeriod({
    required this.month,
    required this.year,
    required this.monthName,
  });

  @override
  String toString() => '$monthName $year';
}

PayrollPeriod resolvePayrollPeriod(
  Map<String, dynamic> payroll, {
  int? fallbackMonth,
  int? fallbackYear,
}) {
  dynamic rawMonth =
      payroll['month'] ??
      payroll['payrollMonth'] ??
      payroll['selectedMonth'] ??
      payroll['periodMonth'];

  dynamic rawYear =
      payroll['year'] ??
      payroll['payrollYear'] ??
      payroll['selectedYear'] ??
      payroll['periodYear'];

  final period =
      payroll['period']?.toString().trim() ??
      payroll['payrollPeriod']?.toString().trim();

  int? month = _parseMonth(rawMonth);
  int? year = int.tryParse(
    rawYear?.toString().trim() ?? '',
  );

  if ((month == null || year == null) &&
      period != null &&
      period.isNotEmpty) {
    final resolved = _parsePeriodString(period);

    month ??= resolved?.month;
    year ??= resolved?.year;
  }

  // Use controlled fallbacks from the selected period in Admin Payroll page
  month ??= fallbackMonth;
  year ??= fallbackYear;

  if (month == null || year == null) {
    throw StateError(
      'Payroll month and year are missing from the selected payroll record.',
    );
  }

  return PayrollPeriod(
    month: month,
    year: year,
    monthName: DateFormat('MMMM').format(
      DateTime(year, month),
    ),
  );
}

int? _parseMonth(dynamic rawMonth) {
  if (rawMonth == null) return null;

  final raw = rawMonth.toString().trim();

  // Try parsing as integer first
  final numericMonth = int.tryParse(raw);
  if (numericMonth != null && numericMonth >= 1 && numericMonth <= 12) {
    return numericMonth;
  }

  // Try parsing as month name (case-insensitive)
  final monthNames = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  return monthNames[raw.toLowerCase()];
}

({int month, int year})? _parsePeriodString(String period) {
  // Try formats: "2026-06", "06/2026", "June 2026", "2026 June"
  
  // Format: "YYYY-MM"
  final yearMonthMatch = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(period);
  if (yearMonthMatch != null) {
    final year = int.tryParse(yearMonthMatch.group(1) ?? '');
    final month = int.tryParse(yearMonthMatch.group(2) ?? '');
    if (year != null && month != null && month >= 1 && month <= 12) {
      return (month: month, year: year);
    }
  }

  // Format: "MM/YYYY"
  final monthYearMatch = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch(period);
  if (monthYearMatch != null) {
    final month = int.tryParse(monthYearMatch.group(1) ?? '');
    final year = int.tryParse(monthYearMatch.group(2) ?? '');
    if (year != null && month != null && month >= 1 && month <= 12) {
      return (month: month, year: year);
    }
  }

  // Format: "MonthName YYYY" or "YYYY MonthName"
  final monthNameMatch = RegExp(r'^([A-Za-z]+)\s+(\d{4})$').firstMatch(period);
  if (monthNameMatch != null) {
    final monthName = monthNameMatch.group(1);
    final year = int.tryParse(monthNameMatch.group(2) ?? '');
    final month = _parseMonth(monthName);
    if (year != null && month != null) {
      return (month: month, year: year);
    }
  }

  // Format: "YYYY MonthName"
  final yearMonthNameMatch = RegExp(r'^(\d{4})\s+([A-Za-z]+)$').firstMatch(period);
  if (yearMonthNameMatch != null) {
    final year = int.tryParse(yearMonthNameMatch.group(1) ?? '');
    final monthName = yearMonthNameMatch.group(2);
    final month = _parseMonth(monthName);
    if (year != null && month != null) {
      return (month: month, year: year);
    }
  }

  return null;
}
