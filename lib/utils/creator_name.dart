/// Shared helpers for rendering a task/record creator in the UI.
///
/// Internal identifiers (Firebase UIDs, UUIDs, service-account ids) must never
/// be shown to users. The backend resolves `createdBy` to `createdByName`; these
/// helpers provide the display fallback and a last line of defence against an
/// identifier reaching the screen.
library;

/// Label used when a creator name cannot be resolved.
const String kUnknownCreatorName = 'Unknown Admin';

/// Matches a UUID or a Firebase-style opaque id (20+ id-safe chars, no spaces).
final RegExp _opaqueIdPattern = RegExp(
  r'^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
  r'|[A-Za-z0-9_-]{20,})$',
  caseSensitive: false,
);

/// Returns `true` when [value] looks like an internal identifier rather than a
/// human-readable name.
bool looksLikeInternalId(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  if (v.contains(' ')) return false; // real names contain spaces
  return _opaqueIdPattern.hasMatch(v);
}

/// Resolves the creator label to display.
///
/// Falls back to [kUnknownCreatorName] when the value is missing, blank, or
/// still looks like a raw identifier (e.g. a legacy task whose creator account
/// was deleted, or an API that could not resolve the name).
String resolveCreatorName(Object? rawName) {
  final name = (rawName ?? '').toString().trim();
  if (name.isEmpty) return kUnknownCreatorName;
  if (looksLikeInternalId(name)) return kUnknownCreatorName;
  return name;
}
