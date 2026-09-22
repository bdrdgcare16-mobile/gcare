// lib/features/onboarding/registration/services/registration_draft_storage_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/organization_registration_draft.dart';

/// Persists the organization-registration draft on-device.
///
/// Local-only storage — the future backend draft API (Milestone 3B) will
/// provide cross-device, server-side drafts. Nothing secret is stored here.
class RegistrationDraftStorageService {
  RegistrationDraftStorageService._();

  static final RegistrationDraftStorageService instance =
      RegistrationDraftStorageService._();

  static const String _draftKey = 'serv_org_registration_draft_v1';
  static const String _archiveKey = 'serv_org_registration_archive_v1';

  Future<void> saveDraft(OrganizationRegistrationDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<OrganizationRegistrationDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final draft = OrganizationRegistrationDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return draft.isEmpty ? null : draft;
    } catch (_) {
      // Corrupt draft — treat as no draft rather than crash the wizard.
      return null;
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  /// Records a previously submitted application so that starting a new one
  /// does not erase all trace of it on this device.
  ///
  /// Non-secret reference data only — the resume credential itself stays in
  /// secure storage (see [OrganizationRegistrationService.archiveResumeToken]).
  Future<void> archiveApplication({
    required String registrationId,
    required String organizationName,
    required String status,
  }) async {
    if (registrationId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = loadArchiveFrom(prefs)
        .where((e) => e['registrationId'] != registrationId)
        .toList();
    existing.add({
      'registrationId': registrationId,
      'organizationName': organizationName,
      'status': status,
      'archivedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_archiveKey, jsonEncode(existing));
  }

  Future<List<Map<String, String>>> loadArchive() async {
    final prefs = await SharedPreferences.getInstance();
    return loadArchiveFrom(prefs);
  }

  List<Map<String, String>> loadArchiveFrom(SharedPreferences prefs) {
    final raw = prefs.getString(_archiveKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
