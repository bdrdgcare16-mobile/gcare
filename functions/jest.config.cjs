module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
  },
  testMatch: ['**/?(*.)+(spec|test).[jt]s?(x)'],
  collectCoverage: false,
  // Sets a safe, loopback-only project/emulator-host env before any test
  // module loads, so a test that forgets to mock ../config/firebase can
  // never resolve to - or reach - a real Firebase project.
  setupFiles: ['<rootDir>/jest.setup.js'],
};
