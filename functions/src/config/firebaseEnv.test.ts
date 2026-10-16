import {
  resolveProjectId,
  isFunctionsEmulator,
  isJest,
  missingEmulatorHosts,
  type FirebaseEnv,
} from './firebaseEnv';

describe('resolveProjectId', () => {
  it('returns null (never a hardcoded project) when nothing is set', () => {
    expect(resolveProjectId({})).toBeNull();
  });

  it('prefers GCLOUD_PROJECT - the GCP-injected value for a real deployment', () => {
    expect(
      resolveProjectId({
        GCLOUD_PROJECT: 'servappbackend',
        APP_PROJECT_ID: 'should-not-win',
      }),
    ).toBe('servappbackend');
  });

  it('falls back to GOOGLE_CLOUD_PROJECT when GCLOUD_PROJECT is absent', () => {
    expect(resolveProjectId({ GOOGLE_CLOUD_PROJECT: 'serv-dev-f2557' })).toBe(
      'serv-dev-f2557',
    );
  });

  it('honors APP_PROJECT_ID - this repo\'s .env/.env.example convention', () => {
    expect(resolveProjectId({ APP_PROJECT_ID: 'serv-dev-f2557' })).toBe(
      'serv-dev-f2557',
    );
  });

  it('falls back to the legacy APP_FIREBASE_PROJECT_ID alias', () => {
    expect(
      resolveProjectId({ APP_FIREBASE_PROJECT_ID: 'serv-dev-f2557' }),
    ).toBe('serv-dev-f2557');
  });

  it('never returns a hardcoded production project id as a silent default', () => {
    const result = resolveProjectId({});
    expect(result).not.toBe('servappbackend');
    expect(result).toBeNull();
  });
});

describe('isFunctionsEmulator / isJest', () => {
  it('isFunctionsEmulator is true only when FUNCTIONS_EMULATOR==="true"', () => {
    expect(isFunctionsEmulator({})).toBe(false);
    expect(isFunctionsEmulator({ FUNCTIONS_EMULATOR: 'false' })).toBe(false);
    expect(isFunctionsEmulator({ FUNCTIONS_EMULATOR: 'true' })).toBe(true);
  });

  it('isJest is true whenever JEST_WORKER_ID is set, regardless of value', () => {
    expect(isJest({})).toBe(false);
    expect(isJest({ JEST_WORKER_ID: '1' })).toBe(true);
  });
});

describe('missingEmulatorHosts', () => {
  const bothHosts: FirebaseEnv = {
    FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
    FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  };

  it('requires nothing in production (neither emulator nor Jest running)', () => {
    expect(missingEmulatorHosts({ GCLOUD_PROJECT: 'servappbackend' })).toEqual(
      [],
    );
  });

  it('requires both emulator hosts when the Functions emulator is running', () => {
    expect(
      missingEmulatorHosts({ FUNCTIONS_EMULATOR: 'true' }),
    ).toEqual(['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']);
  });

  it('passes when the Functions emulator has both hosts attached', () => {
    expect(
      missingEmulatorHosts({ FUNCTIONS_EMULATOR: 'true', ...bothHosts }),
    ).toEqual([]);
  });

  it('requires both emulator hosts when running under Jest - the exact ' +
      'guard that fixed payrollService.test.ts', () => {
    expect(missingEmulatorHosts({ JEST_WORKER_ID: '1' })).toEqual([
      'FIRESTORE_EMULATOR_HOST',
      'FIREBASE_AUTH_EMULATOR_HOST',
    ]);
  });

  it('passes under Jest once jest.setup.js-style hosts are present', () => {
    expect(
      missingEmulatorHosts({ JEST_WORKER_ID: '1', ...bothHosts }),
    ).toEqual([]);
  });

  it('reports only the specific host(s) actually missing', () => {
    expect(
      missingEmulatorHosts({
        JEST_WORKER_ID: '1',
        FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
      }),
    ).toEqual(['FIREBASE_AUTH_EMULATOR_HOST']);
  });
});
