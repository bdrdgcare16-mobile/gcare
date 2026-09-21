// lib/features/onboarding/services/onboarding_storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Storage keys for the initial install onboarding flow.
class OnboardingStorageKeys {
  OnboardingStorageKeys._();

  static const String initialOnboardingCompleted =
      'serv_initial_onboarding_completed';

  static const String acceptedPolicyVersion =
      'serv_accepted_policy_version';

  static const String selectedUserType = 'serv_selected_user_type';

  static const String organizationRegistrationCompleted =
      'serv_organization_registration_completed';
}

/// Allowed user-type values persisted during onboarding.
class OnboardingUserType {
  OnboardingUserType._();

  static const String employee = 'employee';
  static const String hrAdmin = 'hr_admin';
  static const String registerOrganization = 'register_organization';
}

/// Handles persistence for the initial onboarding experience.
///
/// Uses SharedPreferences to stay consistent with the rest of the app.
/// Policy-versioning is prepared on the frontend so a backend-driven policy
/// update can later force a re-acceptance without reworking storage.
class OnboardingStorageService {
  OnboardingStorageService._();

  static final OnboardingStorageService _instance =
      OnboardingStorageService._();

  static OnboardingStorageService get instance => _instance;

  static const String currentPolicyVersion = '1.0';

  /// Whether the user has completed the Welcome → Policies → User Type flow.
  Future<bool> isInitialOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OnboardingStorageKeys.initialOnboardingCompleted) ??
        false;
  }

  /// Marks the initial onboarding flow as completed, records the policy
  /// version accepted, and stores the user type selected by the user.
  Future<void> markInitialOnboardingCompleted({
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      OnboardingStorageKeys.initialOnboardingCompleted,
      true,
    );
    await prefs.setString(
      OnboardingStorageKeys.acceptedPolicyVersion,
      currentPolicyVersion,
    );
    await prefs.setString(
      OnboardingStorageKeys.selectedUserType,
      userType,
    );
  }

  /// Returns the last selected user type, or null if not recorded.
  Future<String?> getSelectedUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OnboardingStorageKeys.selectedUserType);
  }

  /// Marks organization registration as completed. Called once the real
  /// registration flow (Milestone 3) finishes successfully.
  Future<void> markOrganizationRegistrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      OnboardingStorageKeys.organizationRegistrationCompleted,
      true,
    );
  }

  /// Whether organization registration has been completed.
  Future<bool> isOrganizationRegistrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OnboardingStorageKeys.organizationRegistrationCompleted) ??
        false;
  }

  /// Clears onboarding state. Intended for testing/debugging only.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(OnboardingStorageKeys.initialOnboardingCompleted);
    await prefs.remove(OnboardingStorageKeys.acceptedPolicyVersion);
    await prefs.remove(OnboardingStorageKeys.selectedUserType);
    await prefs.remove(OnboardingStorageKeys.organizationRegistrationCompleted);
  }

  /// Records that the user has accepted the current policy version.
  /// Intended for returning users who need to re-accept an updated policy.
  Future<void> acceptPolicyVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      OnboardingStorageKeys.acceptedPolicyVersion,
      currentPolicyVersion,
    );
  }

  /// Checks whether the currently stored accepted policy version differs from
  /// [currentPolicyVersion]. Returns `true` when the user must re-accept
  /// policies (prepared for future backend-driven policy updates).
  Future<bool> shouldShowPolicyUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getString(OnboardingStorageKeys.acceptedPolicyVersion);
    return accepted != currentPolicyVersion;
  }
}
