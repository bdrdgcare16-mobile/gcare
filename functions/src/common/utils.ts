export const normEmail = (e = ""): string => {
  return String(e).trim().toLowerCase();
};

/**
 * Server-side proof that GPS was confirmed OFF during the CURRENT
 * tracking session: a recorded location_disabled/gps_disabled event
 * stamped at or after the session start (currentSessionStartedAt,
 * re-stamped on reopen; startedAt for legacy docs). Unknown or initial
 * state is never OFF - only recorded evidence counts, and events from
 * before the current session boundary do not qualify. The 60s tolerance
 * mirrors the logout session-binding rule for stamp-vs-boundary skew.
 * Shared by trackingAddEvent (notify gate) and reconcilePendingAdmin-
 * Notifies (stale-flag cleanup) - lives here to avoid an import cycle.
 */
export function gpsConfirmedOffThisSession(data: {
  events?: any[];
  currentSessionStartedAt?: string | null;
  startedAt?: string | null;
}): boolean {
  const startMs = Date.parse(String(
    data.currentSessionStartedAt ?? data.startedAt ?? ''));
  const events = Array.isArray(data.events) ? data.events : [];
  return events.some((e: any) => {
    const t = String(e?.type || '');
    if (t !== 'location_disabled' && t !== 'gps_disabled') return false;
    const ts = Date.parse(String(e?.ts || ''));
    return Number.isFinite(ts) &&
      (!Number.isFinite(startMs) || ts >= startMs - 60000);
  });
}