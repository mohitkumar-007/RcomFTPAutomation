import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/profile_page.dart';

void main() {
  patrolTest(
    'TC_USERNAME_001 — Username update reflects in profile header',
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

      final newName = 'RcomUser_${DateTime.now().millisecondsSinceEpoch % 10000}';
      await profile.updateUsername(newName);

      await $(#backButton).tap();
      await $(find.text(newName)).waitUntilVisible(
        timeout: const Duration(seconds: 5),
      );
      expect($(find.text(newName)), findsOneWidget);
    },
  );

  patrolTest(
    'TC_USERNAME_002 — Username with special characters is rejected',
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
      await $(#usernameField).enterText('Invalid!@#User');
      await $(#saveProfileButton).tap();

      await $(find.text('Username can only contain letters and numbers'))
          .waitUntilVisible(timeout: const Duration(seconds: 5));
    },
  );
}
