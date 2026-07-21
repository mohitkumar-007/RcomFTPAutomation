import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/profile_page.dart';

void main() {
  patrolTest(
    'TC_ACCDEL_001 — Account deletion workflow completes and returns to Login',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      // Use a dedicated disposable account for this destructive test
      await LoginPage($).loginWith(
        phone: String.fromEnvironment('DELETE_TEST_PHONE', defaultValue: '+919000000099'),
        otp: Environment.mockOtp,
      );

      final profile = ProfilePage($);
      await profile.openProfile();
      await profile.initiateAccountDeletion();

      // Post-deletion: redirected to Login with a confirmation toast
      await $(find.text('Account deleted successfully')).waitUntilVisible(
        timeout: const Duration(seconds: 15),
      );
      await $(#phoneInputField).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
    },
  );
}
