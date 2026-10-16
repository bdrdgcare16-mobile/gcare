/// Centralized feature visibility flags.
///
/// These flags only control UI visibility. They do not touch backend
/// services, API calls, Firestore collections, or business logic, so a
/// feature can be re-enabled later by flipping its flag back to `true`.
class FeatureFlags {
  FeatureFlags._();

  /// When `false`, the Payroll feature is hidden from both the Admin
  /// dashboard navigation and the Employee "My SERV" grid (payslips).
  ///
  /// Note: intentionally not `const` so guarded widgets are not reported
  /// as dead code by the analyzer while the flag is disabled.
  static bool showPayrollUI = false;
}
