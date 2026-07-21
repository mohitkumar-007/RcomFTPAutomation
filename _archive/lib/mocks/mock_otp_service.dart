/// Intercepts OTP requests on QA environments where the backend is configured
/// to accept a fixed OTP value rather than dispatching a real SMS.
/// No network calls are made from the test side — the QA backend itself
/// reads the MOCK_OTP dart-define embedded in the test APK manifest.
abstract final class MockOtpService {
  static const String fixedOtp = '123456';

  /// Returns the OTP value the QA backend will auto-accept.
  static String get validOtp => fixedOtp;

  /// Any value other than fixedOtp will trigger an "Invalid OTP" response.
  static String get invalidOtp => '000000';
}
