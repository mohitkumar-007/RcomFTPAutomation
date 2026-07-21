import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/helpers/assertion_helper.dart';
import '../../../lib/pages/auth/login_page.dart';

void main() {
  patrolTest(
    'TC_STATIC_001 — Terms of Service page loads and contains required heading',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await $('menuButton').tap();
      await $(find.text('Terms of Service')).tap();

      await AssertionHelper($).assertTextVisible('Terms of Service');
      await AssertionHelper($).assertKeyVisible('tosContent');
    },
  );

  patrolTest(
    'TC_STATIC_002 — Privacy Policy page loads without errors',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await $('menuButton').tap();
      await $(find.text('Privacy Policy')).tap();

      await AssertionHelper($).assertTextVisible('Privacy Policy');
      await AssertionHelper($).assertKeyVisible('privacyContent');
    },
  );
}
