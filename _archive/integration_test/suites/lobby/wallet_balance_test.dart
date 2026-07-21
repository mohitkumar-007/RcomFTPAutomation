import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/helpers/assertion_helper.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/profile_page.dart';

void main() {
  patrolTest(
    'TC_WALLET_001 — Wallet balance is numeric and non-negative',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      final profile = ProfilePage($);
      await profile.openProfile();
      final balance = await profile.readWalletBalance();

      await AssertionHelper($).assertNumericAndNonNegative(balance);
    },
  );
}
