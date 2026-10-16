import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// Centralized tenant feature-entitlement access.
///
/// The authoritative list of enabled features lives on the backend
/// (`companies/<companyId>.enabledFeatures`) and is enforced by API
/// middleware. This service is only a UI gate — it decides which menus,
/// tiles and routes to show.
///
/// Backward compatibility:
///  - If the company document has no `enabledFeatures` field, the backend
///    reports `enabledFeatures: null` (legacy). We treat that as
///    "all features allowed" so existing companies keep working.
///  - If the entitlement fetch fails (offline, transient error), we fall
///    back to the last persisted entitlement, and if none exists we allow
///    everything — matching the previous app behaviour.
///  - `super_admin` (platform admin) is never feature-gated.
class FeatureAccess {
  FeatureAccess._();

  // Feature keys mirrored from the backend catalog.
  static const String dashboard = 'dashboard';
  static const String employees = 'employees';
  static const String attendance = 'attendance';
  static const String geofencing = 'geofencing';
  static const String tracking = 'tracking';
  static const String leave = 'leave';
  static const String payroll = 'payroll';
  static const String onboarding = 'onboarding';
  static const String recruitment = 'recruitment';
  static const String performance = 'performance';
  static const String expenses = 'expenses';
  static const String reports = 'reports';
  static const String tasks = 'tasks';
  static const String events = 'events';
  static const String feedback = 'feedback';
  static const String rewards = 'rewards';
  static const String notifications = 'notifications';

  // Persisted snapshot is namespaced per tenant+user so a previous account's
  // entitlements are never shown to a different session on the same device.
  static const String _prefsKeyPrefix = 'feature_access';
  // Pre-namespacing storage keys — still cleared on logout.
  static const String _oldPrefsKey = 'enabledFeatures';
  static const String _oldPrefsLegacyKey = 'featuresLegacy';

  static Set<String> _features = <String>{};
  static bool _loaded = false;
  static bool _legacy = true; // default: allow everything until we know better
  static int? _maxUsers;
  static int? _currentUsers;
  static String _companyStatus = 'active';

  /// Scope of the currently active entitlement set ('' until known).
  static String _scopeKey = '';

  /// Derive the storage scope from the current session / login payload.
  static String _resolveScope({String? companyId, String? userId}) {
    final cid = (companyId ?? CompanyData.companyId).trim();
    final uid = (userId ?? '').trim().isNotEmpty
        ? userId!.trim()
        : (CompanyData.empid.isNotEmpty
            ? CompanyData.empid
            : CompanyData.email);
    return '${cid}_${uid}';
  }

  static String get _storageKey =>
      '${_prefsKeyPrefix}_${_scopeKey.isNotEmpty ? _scopeKey : 'unknown'}';

  /// True once entitlements have been loaded this session (or restored).
  static bool get isLoaded => _loaded;

  /// Legacy companies have no configured entitlement -> all features on.
  static bool get isLegacy => _legacy;

  static int? get maxUsers => _maxUsers;
  static int? get currentUsers => _currentUsers;
  static String get companyStatus => _companyStatus;

  /// Feature check used across the UI. Never throws.
  static bool has(String feature) {
    if (!_loaded) return true;
    if (CompanyData.role == 'super_admin') return true;
    if (_legacy) return true;
    return _features.contains(feature.trim().toLowerCase());
  }

  /// Any of the given features enabled.
  static bool hasAny(List<String> features) =>
      features.any((f) => has(f));

  /// Apply a server/persisted entitlement payload.
  static void apply({
    required List<String>? enabledFeatures,
    List<String>? effectiveFeatures,
    int? maxUsers,
    int? currentUsers,
    String? status,
    String? companyId,
    String? userId,
  }) {
    final scope = _resolveScope(companyId: companyId, userId: userId);
    if (scope.isNotEmpty && scope != '_') _scopeKey = scope;
    _maxUsers = maxUsers;
    _currentUsers = currentUsers;
    if (status != null && status.isNotEmpty) _companyStatus = status;

    if (enabledFeatures == null) {
      _legacy = true;
      _features = <String>{};
    } else {
      _legacy = false;
      // Prefer the server-computed effective set (dependency closure
      // already applied); fall back to the raw list.
      final src = (effectiveFeatures != null && effectiveFeatures.isNotEmpty)
          ? effectiveFeatures
          : enabledFeatures;
      _features =
          src.map((f) => f.trim().toLowerCase()).toSet();
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    try {
      final payload = jsonEncode({
        'legacy': _legacy,
        'features': _features.toList(),
        'maxUsers': _maxUsers,
        'currentUsers': _currentUsers,
        'status': _companyStatus,
      });
      try {
        html.window.localStorage[_storageKey] = payload;
      } catch (_) {}
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_storageKey, payload);
    } catch (_) {}
  }

  static Future<void> _restoreFromStorage() async {
    try {
      String? raw;
      final sp = await SharedPreferences.getInstance();
      raw = sp.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        try {
          raw = html.window.localStorage[_storageKey];
        } catch (_) {}
      }
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      apply(
        enabledFeatures: decoded['legacy'] == true
            ? null
            : (decoded['features'] as List?)
                ?.map((e) => e.toString())
                .toList(),
        maxUsers: decoded['maxUsers'] is num
            ? (decoded['maxUsers'] as num).toInt()
            : null,
        currentUsers: decoded['currentUsers'] is num
            ? (decoded['currentUsers'] as num).toInt()
            : null,
        status: decoded['status']?.toString(),
      );
    } catch (_) {}
  }

  /// Load entitlements: last persisted snapshot first (so the UI can gate
  /// immediately), then a live refresh from the backend.
  static Future<void> load({String? token}) async {
    // Resolve the tenant/user scope before touching storage — the persisted
    // key is namespaced per session identity.
    final scope = _resolveScope();
    if (scope.isNotEmpty && scope != '_') _scopeKey = scope;
    await _restoreFromStorage();
    await refresh(token: token);
  }

  /// Fetch fresh entitlements from the backend. Safe to call on login,
  /// session restore, or when the platform admin may have changed them.
  static Future<void> refresh({String? token}) async {
    final t = (token != null && token.isNotEmpty)
        ? token
        : CompanyData.token;
    if (t.isEmpty) return;

    try {
      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/company/entitlements'),
            headers: {
              'Authorization': 'Bearer $t',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) return;

      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      if (data is! Map) return;

      final enabled = data['enabledFeatures'];
      final effective = data['effectiveFeatures'];

      apply(
        enabledFeatures: enabled == null
            ? null
            : (enabled as List).map((e) => e.toString()).toList(),
        effectiveFeatures: effective == null
            ? null
            : (effective as List).map((e) => e.toString()).toList(),
        maxUsers:
            data['maxUsers'] is num ? (data['maxUsers'] as num).toInt() : null,
        currentUsers: data['currentUsers'] is num
            ? (data['currentUsers'] as num).toInt()
            : null,
        status: data['status']?.toString(),
        companyId: data['companyId']?.toString(),
      );

      await _persist();
      debugPrint('[FeatureAccess] loaded '
          'legacy=$_legacy features=${_features.length}');
    } catch (e) {
      debugPrint('[FeatureAccess] refresh failed: $e');
    }
  }

  /// Seed directly from a login response body (avoid an extra round trip).
  /// The backend returns `enabledFeatures` (null for legacy) and `maxUsers`
  /// either at top level or nested under `data`.
  static void seedFromLoginResponse(Map<String, dynamic> body) {
    final inner = body['data'];
    final src = (inner is Map) ? inner : body;
    if (!src.containsKey('enabledFeatures')) return;
    final raw = src['enabledFeatures'];
    apply(
      enabledFeatures:
          raw == null ? null : (raw as List).map((e) => e.toString()).toList(),
      maxUsers:
          src['maxUsers'] is num ? (src['maxUsers'] as num).toInt() : null,
      companyId: src['companyId']?.toString(),
      userId: (src['uid'] ?? src['userId'] ?? src['id'])?.toString(),
    );
    unawaited(_persist());
  }

  /// Clear cached entitlements (logout / account switch).
  static Future<void> clear() async {
    _features = <String>{};
    _loaded = false;
    _legacy = true;
    _maxUsers = null;
    _currentUsers = null;
    _companyStatus = 'active';
    try {
      try {
        html.window.localStorage.remove(_storageKey);
        html.window.localStorage.remove(_oldPrefsKey);
        html.window.localStorage.remove(_oldPrefsLegacyKey);
      } catch (_) {}
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_storageKey);
      await sp.remove(_oldPrefsKey);
      await sp.remove(_oldPrefsLegacyKey);
    } catch (_) {}
    _scopeKey = '';
  }
}
