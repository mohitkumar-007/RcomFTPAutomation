import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/profile_page.dart';

void main() {
  patrolTest(
    'TC_LOGOUT_001 — Logout returns user to Login screen',
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
      await profile.logout();

      // Login screen should be visible again
      await $(#phoneInputField).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
      expect($(#phoneInputField), findsOneWidget);
    },
  );
}
