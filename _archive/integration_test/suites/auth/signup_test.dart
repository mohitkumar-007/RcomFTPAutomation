import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/auth/signup_page.dart';
import '../../../lib/pages/lobby/lobby_page.dart';

void main() {
  patrolTest(
    'TC_SIGNUP_001 — New user signup completes and lands on Lobby',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();

      // Navigate from login to signup
      await $(find.text('Create Account')).tap();

      final signupPage = SignupPage($);
      await signupPage.completeSignup(
        username: 'TestUser_${DateTime.now().millisecondsSinceEpoch}',
        email: 'testuser_${DateTime.now().millisecondsSinceEpoch}@testmail.com',
      );

      // After signup, the app logs in automatically and redirects to Lobby
      await LobbyPage($).assertLobbyVisible();
    },
  );

  patrolTest(
    'TC_SIGNUP_002 — Duplicate username shows validation error',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await $(find.text('Create Account')).tap();

      final signupPage = SignupPage($);
      await signupPage.enterUsername('existinguser123');
      await signupPage.enterEmail('new_${DateTime.now().millisecondsSinceEpoch}@test.com');
      await signupPage.acceptTerms();
      await signupPage.submitSignup();

      await signupPage.assertValidationError('usernameField', 'Username already taken');
    },
  );
}
