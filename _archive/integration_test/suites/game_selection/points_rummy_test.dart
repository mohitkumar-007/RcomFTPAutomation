import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/game_selection/game_lobby_page.dart';
import '../../../lib/pages/gameplay/table_page.dart';

void main() {
  patrolTest(
    'TC_PTS_001 — Points Rummy table loads after joining',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await GameLobbyPage($).selectTableAndJoin(variant: RummyVariant.points);
      await TablePage($).waitForTableToLoad();
    },
  );

  patrolTest(
    'TC_PTS_002 — Points Rummy game card is visible in Lobby',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await $(Keys.pointsRummyCard).waitUntilVisible(timeout: const Duration(seconds: 15));
      expect($(Keys.pointsRummyCard), findsOneWidget);
    },
  );
}
