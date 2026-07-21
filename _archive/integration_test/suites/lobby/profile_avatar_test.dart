import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/lobby/profile_page.dart';

void main() {
  late ProfilePage profilePage;

  setUp(($) async {
    profilePage = ProfilePage($);
  });

  Future<void> _loginAndOpenProfile(PatrolIntegrationTester $) async {
    await $.pumpWidgetAndSettle(const RummyApp());
    await PermissionHandlerComponent($).dismissStartupPermissions();
    await LoginPage($).loginWith(
      phone: Environment.testPhone,
      otp: Environment.mockOtp,
    );
    await profilePage.openProfile();
  }

  patrolTest(
    'TC_PROFILE_001 — Avatar selection persists after save',
    config: kPatrolConfig,
    ($) async {
      profilePage = ProfilePage($);
      await _loginAndOpenProfile($);
      await profilePage.selectAvatar(avatarIndex: 3);
      await profilePage.assertSelectedAvatar(3);
    },
  );

  patrolTest(
    'TC_PROFILE_002 — Different avatar replaces previously selected one',
    config: kPatrolConfig,
    ($) async {
      profilePage = ProfilePage($);
      await _loginAndOpenProfile($);
      await profilePage.selectAvatar(avatarIndex: 1);
      await profilePage.selectAvatar(avatarIndex: 5);
      await profilePage.assertSelectedAvatar(5);
    },
  );
}
