import 'package:patrol/patrol.dart';
import '../../config/environment.dart';
import '../../config/test_constants.dart';

/// Selectors derived from live uiautomator dumps of
/// com.rummydotcom.indianrummycashgame (stage build, landscape).
/// Flutter canvas app — no resource-ids; selectors use content-desc or class.
class LoginPage {
  const LoginPage(this.$);
  final PatrolIntegrationTester $;

  // ── Selectors ────────────────────────────────────────────────────────────
  static const _phoneInputClass  = 'android.widget.EditText';
  static const _continueDesc     = 'Continue';
  static const _googleDesc       = 'Google';
  static const _guestDesc        = 'Play as Guest';
  static const _signInLabel      = 'Sign in to get started';

  // OTP screen
  static const _otpScreenLabel   = 'Enter OTP';
  static const _otpInputClass    = 'android.widget.EditText';
  static const _changeDesc       = 'Change';
  static const _resendPrefix     = 'Resend in';

  // ── Login screen actions ─────────────────────────────────────────────────

  Future<void> assertLoginScreenVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _signInLabel),
      timeout: Timeouts.medium,
    );
  }

  Future<void> enterPhoneNumber(String phone) async {
    await $.native.waitUntilVisible(
      Selector(className: _phoneInputClass),
      timeout: Timeouts.medium,
    );
    await $.native.tap(Selector(className: _phoneInputClass));
    await $.native.enterText(
      Selector(className: _phoneInputClass),
      text: phone,
    );
  }

  Future<void> tapContinue() async {
    await $.native.waitUntilVisible(
      Selector(description: _continueDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _continueDesc));
  }

  Future<void> tapGoogleSignIn() async {
    await $.native.waitUntilVisible(
      Selector(description: _googleDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _googleDesc));
  }

  Future<void> tapPlayAsGuest() async {
    await $.native.waitUntilVisible(
      Selector(description: _guestDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _guestDesc));
  }

  // ── OTP screen actions ───────────────────────────────────────────────────

  Future<void> assertOtpScreenVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _otpScreenLabel),
      timeout: Timeouts.medium,
    );
  }

  Future<void> enterOtp([String otp = Environment.stageOtp]) async {
    await $.native.waitUntilVisible(
      Selector(className: _otpInputClass),
      timeout: Timeouts.medium,
    );
    await $.native.tap(Selector(className: _otpInputClass));
    await $.native.enterText(
      Selector(className: _otpInputClass),
      text: otp,
    );
    // OTP auto-submits after all 6 digits are entered — no explicit verify tap needed.
  }

  Future<void> tapChangeNumber() async {
    await $.native.tap(Selector(description: _changeDesc));
  }

  Future<bool> isResendAvailable() async {
    // Resend becomes tappable once countdown reaches 0 (desc changes from
    // "Resend in X sec" to just "Resend").
    try {
      await $.native.waitUntilVisible(
        Selector(description: 'Resend'),
        timeout: const Duration(seconds: 3),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Composite flows ──────────────────────────────────────────────────────

  /// Full login: phone → Continue → OTP (stage hardcoded 123456) → lobby.
  Future<void> loginWith({required String phone}) async {
    await assertLoginScreenVisible();
    await enterPhoneNumber(phone);
    await tapContinue();
    await assertOtpScreenVisible();
    await enterOtp();
  }
}
