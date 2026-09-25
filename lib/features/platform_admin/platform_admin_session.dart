// lib/features/platform_admin/platform_admin_session.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

/// Browser-portal session for the Platform Admin role (Milestone 3D-B).
///
/// The SERV JWT is kept in [CompanyData.token] (used by
/// PlatformAdminRegistrationService) and mirrored into browser
/// localStorage so a page refresh restores the session. The role must be
/// `platform_admin` — anything else is treated as unauthenticated here.
/// Server-side enforcement lives in roleMiddleware(['platform_admin']);
/// this class is only UX gating.
class PlatformAdminSession {
  PlatformAdminSession._();

  static const _kToken = 'serv_pa_token_v1';
  static const _kEmail = 'serv_pa_email_v1';
  static const _kRole = 'serv_pa_role_v1';

  static const requiredRole = 'platform_admin';

  static String get email =>
      html.window.localStorage[_kEmail] ?? '';

  /// True when a stored session exists AND carries the portal role.
  static bool get isSignedIn =>
      html.window.localStorage[_kToken]?.isNotEmpty == true &&
      html.window.localStorage[_kRole] == requiredRole;

  /// Call after a successful backend login that returned role
  /// 'platform_admin'.
  static void save({required String token, required String email}) {
    html.window.localStorage[_kToken] = token;
    html.window.localStorage[_kEmail] = email;
    html.window.localStorage[_kRole] = requiredRole;
    CompanyData.token = token;
    CompanyData.role = requiredRole;
    CompanyData.email = email;
  }

  /// Restores a stored session into CompanyData. Returns false when no
  /// valid portal session exists (caller should route to login).
  static bool restore() {
    if (!isSignedIn) return false;
    CompanyData.token = html.window.localStorage[_kToken]!;
    CompanyData.role = requiredRole;
    CompanyData.email = email;
    return true;
  }

  static Future<void> signOut() async {
    // Blank values first (the non-web stub's remove() is a no-op), then
    // remove the keys on real browser storage.
    html.window.localStorage[_kToken] = '';
    html.window.localStorage[_kEmail] = '';
    html.window.localStorage[_kRole] = '';
    html.window.localStorage.remove(_kToken);
    html.window.localStorage.remove(_kEmail);
    html.window.localStorage.remove(_kRole);
    CompanyData.token = '';
    CompanyData.role = '';
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // best-effort — local state is already cleared
    }
  }
}
