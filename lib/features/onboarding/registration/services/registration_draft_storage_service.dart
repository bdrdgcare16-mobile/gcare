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
}
