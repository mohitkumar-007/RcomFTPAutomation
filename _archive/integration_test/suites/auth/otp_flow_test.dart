import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/auth/otp_page.dart';

void main() {
  patrolTest(
    'TC_OTP_001 — OTP screen is displayed after valid phone entry',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      final loginPage = LoginPage($);
      await loginPage.enterPhoneNumber(Environment.testPhone);
      await loginPage.requestOtp();

      await OtpPage($).assertOtpScreenVisible();
    },
  );

  patrolTest(
    'TC_OTP_002 — Resend button is in cooldown immediately after OTP request',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      final loginPage = LoginPage($);
      await loginPage.enterPhoneNumber(Environment.testPhone);
      await loginPage.requestOtp();

      await OtpPage($).assertResendCooldownActive();
    },
  );

  patrolTest(
    'TC_OTP_003 — Empty OTP submission shows required field error',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      final loginPage = LoginPage($);
      await loginPage.enterPhoneNumber(Environment.testPhone);
      await loginPage.requestOtp();
      await loginPage.submitOtp();

      await loginPage.assertLoginError('Please enter the OTP');
    },
  );
}
