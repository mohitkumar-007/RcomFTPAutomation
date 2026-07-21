import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/components/game/action_panel_component.dart';
import '../../../lib/components/game/scoreboard_component.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/game_selection/game_lobby_page.dart';
import '../../../lib/pages/gameplay/table_page.dart';

void main() {
  patrolTest(
    'TC_TABLEUI_001 — Action panel is visible after table loads',
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

      final actionPanel = ActionPanelComponent($);
      final dropEnabled = await actionPanel.isDropEnabled();
      expect(dropEnabled, isTrue);
    },
  );

  patrolTest(
    'TC_TABLEUI_002 — Scoreboard is visible on game end',
    config: kPatrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(const RummyApp());
      await PermissionHandlerComponent($).dismissStartupPermissions();
      await LoginPage($).loginWith(
        phone: Environment.testPhone,
        otp: Environment.mockOtp,
      );

      await GameLobbyPage($).selectTableAndJoin(variant: RummyVariant.points);
      final tablePage = TablePage($);
      await tablePage.waitForTableToLoad();
      await tablePage.tapDrop();
      await tablePage.confirmDrop();

      await ScoreboardComponent($).assertScoreboardVisible();
    },
  );
}
