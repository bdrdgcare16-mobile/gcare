// functions/src/services/attendanceGeoPolicy.ts
// Centralized company-level attendance/geofence policy resolution.
//
// Two attendance modes exist:
//   MODE A (normal)      — attendance enabled, geofencing disabled.
//   MODE B (geofenced)   — attendance enabled + explicit 'geofencing' feature.
//
// Backward compatibility:
//   - LEGACY tenants (companies doc exists, enabledFeatures absent) are NEVER
//     granted 'geofencing' through resolveEffectiveFeatures/companyHasFeature.
//     Instead they run in legacyCompatibilityMode, which preserves the
//     pre-geofencing implicit behaviour: radius enforcement applies only when
//     an officeLocations doc happens to match the employee's branch, and a
//     missing office produces the historical "No matching branch" pending
//     other-location event (never a configuration error).
//   - Explicit-feature companies without 'geofencing' run MODE A even if
//     officeLocations docs exist — geofencing is never inferred from data.
//
// companyId must always come from the verified JWT — never from request
// input. Callers should resolve once per request and reuse the result.

import {
  getCompanyEntitlementSafe,
  CompanyEntitlement,
} from './entitlementService';

export type GeoPolicySource =
  | 'feature-flag'      // explicit enabledFeatures contains 'geofencing'
  | 'explicit-disabled' // explicit enabledFeatures without 'geofencing'
  | 'legacy-implicit'   // legacy tenant — pre-geofencing implicit behaviour
  | 'unresolved';       // entitlement could not be resolved — fail safe

export interface AttendanceGeoPolicy {
  companyId: string;
  /** false when the entitlement lookup failed or the company is unknown */
  resolved: boolean;
  /** tenant has the 'attendance' feature (legacy => true) */
  attendanceEnabled: boolean;
  /**
   * Explicit company-level geofencing entitlement. Never true for legacy
   * tenants and never inferred from officeLocations document existence.
   */
  geofencingEnabled: boolean;
  /**
   * Legacy tenant compatibility: preserve the historical implicit behaviour
   * (enforce only when a matching office exists; missing office is not a
   * configuration error).
   */
  legacyCompatibilityMode: boolean;
  configurationSource: GeoPolicySource;
}

function unresolved(companyId: string): AttendanceGeoPolicy {
  return {
    companyId,
    resolved: false,
    attendanceEnabled: false,
    geofencingEnabled: false,
    legacyCompatibilityMode: false,
    configurationSource: 'unresolved',
  };
}

function fromEntitlement(ent: CompanyEntitlement): AttendanceGeoPolicy {
  if (ent.lookupFailed || !ent.exists) {
    return unresolved(ent.companyId);
  }

  const attendanceEnabled = ent.isLegacy
    ? true
    : (ent.effectiveFeatures?.has('attendance') ?? true);

  if (ent.isLegacy) {
    return {
      companyId: ent.companyId,
      resolved: true,
      attendanceEnabled,
      // Legacy companies never get the explicit geofencing feature; their
      // historical implicit radius enforcement is preserved via this flag.
      geofencingEnabled: false,
      legacyCompatibilityMode: true,
      configurationSource: 'legacy-implicit',
    };
  }

  const geofencingEnabled =
    ent.effectiveFeatures?.has('geofencing') ?? false;

  return {
    companyId: ent.companyId,
    resolved: true,
    attendanceEnabled,
    geofencingEnabled,
    legacyCompatibilityMode: false,
    configurationSource: geofencingEnabled
      ? 'feature-flag'
      : 'explicit-disabled',
  };
}

/**
 * Resolve the effective attendance geo policy for a company.
 * Uses the same fail-closed entitlement lookup as featureMiddleware
 * (60s last-known-valid cache on transient failures).
 */
export async function resolveAttendanceGeoPolicy(
  companyId: string,
): Promise<AttendanceGeoPolicy> {
  const id = String(companyId || '').trim();
  if (!id) return unresolved(id);
  try {
    const ent = await getCompanyEntitlementSafe(id);
    return fromEntitlement(ent);
  } catch (e) {
    console.error('[geoPolicy] resolution failed for', id, e);
    return unresolved(id);
  }
}
