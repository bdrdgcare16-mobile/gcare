// lib/models/hrms_features.dart

/// Central HRMS feature-capability mapping. Mirrors the backend
/// CANONICAL_FEATURES / BASIC_HRMS_FEATURES in
/// functions/src/models/organizationRegistration.ts.
///
/// `shifts` is the canonical key for the "Shift Management" module.
library;

/// BASIC HRMS — mandatory core modules for every activated SERV HRMS
/// organization. Auto-selected and locked in the registration UI, injected
/// server-side into requestedFeatures, and always present in
/// companyProfile.enabledFeatures after activation.
const List<String> kBasicHrmsFeatures = [
  'attendance',
  'employee_master',
  'feedback',
  'shifts',
];

/// Optional modules the applicant may select.
///
/// Canonical catalogue — mirrors the backend CANONICAL_FEATURES. Historical
/// registrations and enabledFeatures may contain any of these keys; every
/// consumer must tolerate all of them even when they are not selectable.
const List<String> kOptionalHrmsFeatures = [
  'organization_structure',
  'users_and_roles',
  'location_tracking',
  'tasks',
  'leave_management',
  'payroll',
  'recruitment',
  'performance',
  'reporting',
  'events',
];

/// Optional modules with a genuine usable implementation in the current
/// product (backend routes + reachable UI) — the only ones offered as
/// selectable during registration. Keys excluded here are NOT deleted
/// from stored data; older registrations simply cannot select them anew.
const Set<String> kImplementedOptionalFeatures = {
  'location_tracking',
  'tasks',
  'leave_management',
  'payroll',
  'performance',
  'events',
};

/// Human-readable labels for feature chips / review surfaces.
const Map<String, String> kFeatureLabels = {
  'employee_master': 'Employee Master',
  'organization_structure': 'Organization Structure',
  'users_and_roles': 'Users and Roles',
  'attendance': 'Attendance',
  'location_tracking': 'Location Tracking',
  'tasks': 'Tasks',
  'shifts': 'Shift Management',
  'leave_management': 'Leave Management',
  'payroll': 'Payroll',
  'recruitment': 'Recruitment',
  'performance': 'Performance',
  'reporting': 'Reporting',
  'feedback': 'Feedback',
  'events': 'Events',
};

/// Whether a feature id is part of the always-on Basic HRMS core.
bool isBasicHrmsFeature(String id) => kBasicHrmsFeatures.contains(id);
