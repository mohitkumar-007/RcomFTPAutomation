import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/lobby_page.dart';

void main() {
  late LoginPage loginPage;
  late LobbyPage lobbyPage;

  setUp(($) async {
    loginPage = LoginPage($);
    lobbyPage = LobbyPage($);
  });

  patrolTest(
    'TC_AUTH_001 — Successful OTP login navigates to Lobby',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      await loginPage.loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await lobbyPage.assertLobbyVisible();
    },
  );

  patrolTest(
    'TC_AUTH_002 — Invalid OTP shows inline error message',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      await loginPage.enterPhoneNumber(Environment.testPhone);
      await loginPage.requestOtp();
      await loginPage.enterOtp('000000');
      await loginPage.submitOtp();

      await loginPage.assertLoginError('Invalid OTP. Please try again.');
    },
  );

  patrolTest(
    'TC_AUTH_003 — OTP resend button is initially disabled after request',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      await loginPage.enterPhoneNumber(Environment.testPhone);
      await loginPage.requestOtp();

      // Immediately after requesting OTP, resend should be in cooldown
      final resendEnabled = await loginPage.isResendEnabled();
      expect(resendEnabled, isFalse);
    },
  );
}
