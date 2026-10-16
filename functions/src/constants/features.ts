// Central catalog of tenant-level feature entitlements.
// Platform Admin (platform_admin) assigns a subset of these to each company.

export interface FeatureDefinition {
  key: string;
  label: string;
  // Other feature keys that must also be enabled for this feature to work.
  requires: string[];
}

export const FEATURE_CATALOG: FeatureDefinition[] = [
  { key: 'dashboard',    label: 'Dashboard',            requires: [] },
  { key: 'employees',    label: 'Employee Management',  requires: [] },
  // Attendance is meaningless without staff: Employee Management is a core
  // support dependency, so an "Attendance + Tracking" tenant can still create
  // and manage employees.
  { key: 'attendance',   label: 'Attendance',           requires: ['employees'] },
  // Geofencing is an OPTIONAL company-level attendance policy, not an
  // operational module: it switches check-in/out to office-radius
  // enforcement (see attendanceGeoPolicy service). It must never be granted
  // implicitly to legacy tenants — resolvers handle isLegacy explicitly.
  { key: 'geofencing',   label: 'Geofencing',           requires: ['attendance'] },
  { key: 'tracking',     label: 'Location Tracking',    requires: ['attendance'] },
  { key: 'leave',        label: 'Leave Management',     requires: [] },
  { key: 'payroll',      label: 'Payroll',              requires: ['attendance'] },
  { key: 'onboarding',   label: 'Onboarding',           requires: [] },
  { key: 'recruitment',  label: 'Recruitment',          requires: [] },
  { key: 'performance',  label: 'Performance',          requires: [] },
  { key: 'expenses',     label: 'Expenses',             requires: [] },
  { key: 'reports',      label: 'Reports',              requires: ['attendance'] },
  { key: 'tasks',        label: 'Tasks',                requires: [] },
  { key: 'events',       label: 'Events',               requires: [] },
  { key: 'feedback',     label: 'Feedback',             requires: [] },
  { key: 'rewards',      label: 'Rewards',              requires: [] },
  { key: 'notifications', label: 'Push Notifications',  requires: [] },
];

export const FEATURE_KEYS: string[] = FEATURE_CATALOG.map((f) => f.key);

const FEATURE_LABELS: Record<string, string> = Object.fromEntries(
  FEATURE_CATALOG.map((f) => [f.key, f.label]),
);

const FEATURE_REQUIRES: Record<string, string[]> = Object.fromEntries(
  FEATURE_CATALOG.map((f) => [f.key, f.requires]),
);

export function isKnownFeature(key: string): boolean {
  return key in FEATURE_LABELS;
}

export function featureLabel(key: string): string {
  return FEATURE_LABELS[key] || key;
}

/**
 * Validate a requested enabledFeatures list.
 * Returns { ok, unknown, missingDeps } where missingDeps lists human-readable
 * dependency violations such as "Location Tracking requires Attendance".
 */
export function validateFeatureSelection(input: unknown): {
  ok: boolean;
  features: string[];
  unknown: string[];
  missingDeps: string[];
} {
  const raw = Array.isArray(input) ? input : [];
  const features = Array.from(
    new Set(
      raw
        .map((v) => String(v || '').trim().toLowerCase())
        .filter((v) => v.length > 0),
    ),
  );

  const unknown = features.filter((f) => !isKnownFeature(f));

  const set = new Set(features);
  const missingDeps: string[] = [];
  for (const f of features) {
    for (const dep of FEATURE_REQUIRES[f] || []) {
      if (!set.has(dep)) {
        missingDeps.push(`${featureLabel(f)} requires ${featureLabel(dep)}`);
      }
    }
  }

  return {
    ok: unknown.length === 0 && missingDeps.length === 0,
    features,
    unknown,
    missingDeps,
  };
}

/**
 * Return the effective feature set for a stored enabledFeatures array:
 * dependency closure is applied so a stored config that enables `tracking`
 * but somehow lacks `attendance` still functions.
 */
export function resolveEffectiveFeatures(enabled: string[]): Set<string> {
  const effective = new Set<string>();
  const queue = enabled.map((f) => String(f).toLowerCase());

  while (queue.length) {
    const f = queue.pop() as string;
    if (!isKnownFeature(f) || effective.has(f)) continue;
    effective.add(f);
    for (const dep of FEATURE_REQUIRES[f] || []) {
      if (!effective.has(dep)) queue.push(dep);
    }
  }

  return effective;
}
