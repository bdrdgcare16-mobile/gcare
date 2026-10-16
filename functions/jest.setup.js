// Runs once before any test module loads (wired via jest.config.cjs
// `setupFiles`). Guarantees that even a test which forgets to
// `jest.mock('../config/firebase', ...)` can never reach real Firestore/Auth:
// - APP_PROJECT_ID is set to an obviously-fake test project id (never
//   'servappbackend' or 'serv-dev-f2557'), so nothing can be mistaken for a
//   real environment.
// - FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST point the Admin
//   SDK at local loopback addresses. No emulator actually needs to be
//   running at these ports for unit tests - any code path that isn't
//   mocked and genuinely tries to perform a Firestore/Auth call will get a
//   local connection-refused error, never a request to the real network.
//
// Only sets a value when one isn't already present, so a real emulator
// suite (`firebase emulators:exec -- npm test`) or CI config can still
// override these with real emulator hosts/ports.
process.env.APP_PROJECT_ID = process.env.APP_PROJECT_ID || 'serv-jest-test-project';
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
