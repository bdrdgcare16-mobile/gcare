import 'package:flutter/material.dart';

/// Maps the backend `officePresence` classification to a display label.
/// Returns null for unknown/missing values so callers can hide the label.
String? officePresenceLabel(String? presence) {
  switch (presence) {
    case 'inside':
      return 'Inside Office';
    case 'outside':
      return 'Outside Office';
    case 'uncertain':
      return 'Location Uncertain';
    case 'unavailable':
      return 'Location Unavailable';
  }
  return null;
}

/// Badge/indicator color matching each office-presence classification.
Color officePresenceColor(String? presence) {
  switch (presence) {
    case 'inside':
      return const Color(0xFF10B981);
    case 'outside':
      return const Color(0xFFEF4444);
    case 'uncertain':
      return const Color(0xFFF59E0B);
    case 'unavailable':
      return const Color(0xFF6B7280);
  }
  return const Color(0xFF6B7280);
}
