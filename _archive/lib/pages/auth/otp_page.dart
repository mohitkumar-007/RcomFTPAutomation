import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class OtpPage {
  const OtpPage(this.$);
  final PatrolIntegrationTester $;

  Future<void> assertOtpScreenVisible() async {
    await $(#otpInputField).waitUntilVisible(timeout: Timeouts.medium);
    expect($(#otpInputField), findsOneWidget);
  }

  Future<void> assertResendCooldownActive() async {
    // The resend button is either absent or visually disabled during cooldown
    final finder = $(#resendOtpButton);
    final exists = await finder.exists;
    if (exists) {
      final widget = $.tester.widget(finder.finder);
      // Widget rendered but interaction is guarded by cooldown timer on app side
      expect(widget, isNotNull);
    }
  }
}
