// lib/models/company_data.dart

import 'package:cross_file/cross_file.dart';

class CompanyData {
  static String companyName  = '';
  static String email        = '';
  static String phone        = '';
  static String website      = '';
  static String adminName    = '';
  static String adminRole    = '';
  static String role = '';

  /// Non-authoritative display classification returned by the backend.
  /// 'hr' marks accounts created via the Company Admin "HR Management"
  /// flow; their authorization role is 'admin'. Never send this value to
  /// the backend for authorization decisions.
  static String displayRole = '';

  /// Human-facing label for the signed-in user's role. Authorization
  /// always uses [role]; this is only for UI surfaces that render the
  /// role (dashboard title, drawer header, profile).
  static String get roleLabel {
    if (displayRole == 'hr') return 'HR';
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'company_admin':
        return 'Company Admin';
      case 'hr':
        return 'HR';
      case 'super_admin':
      case 'platform_admin':
        return 'Platform Admin';
      case 'employee':
        return 'Employee';
      default:
        return role;
    }
  }

  static String token = '';
  static String empid = '';
  static String companyId = '';
  static XFile? logoFile;


  static var profile;

  static var userName;

  static var name;

  static var employeeProfile;

  
}