import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../../lib/bridges/flame_game_bridge.dart';
import '../../../lib/config/environment.dart';
import '../../../lib/config/patrol_config.dart';
import '../../../lib/components/common/permission_handler_component.dart';
import '../../../lib/helpers/wait_helper.dart';
import '../../../lib/mocks/mock_game_server.dart';
import '../../../lib/pages/auth/login_page.dart';
import '../../../lib/pages/game_selection/game_lobby_page.dart';
import '../../../lib/pages/gameplay/table_page.dart';

void main() {
  late MockGameServer mockServer;
  final bridge = FlameGameBridge();

  setUpAll(() async {
    if (Environment.useMockGameServer) {
      mockServer = MockGameServer();
      await mockServer.start();

      mockServer.onAction('JOIN_TABLE', (_) => {
        'type': 'GAME_STATE_UPDATE',
        'payload': {
          'status': 'IN_PROGRESS',
          'currentTurn': 'test_player',
          'hand': ['AS','2S','3S','4H','5H','6H','7D','8D','9D','10C','JC','QC','KC'],
          'joker': 'KS',
          'deckCount': 39,
        },
      });

      mockServer.onAction('DROP', (req) => {
        'type': 'DROP_RESULT',
        'payload': {
          'playerId': req['playerId'],
          'isFirstDrop': req['isFirstDrop'],
          'penalty': (req['isFirstDrop'] as bool? ?? false) ? 20 : 40,
          'status': 'GAME_OVER',
        },
      });
    }
  });

  tearDownAll(() async {
    if (Environment.useMockGameServer) {
      await mockServer.stop();
    }
  });

  patrolTest(
    'TC_GAME_001 — First drop deducts 20 penalty points',
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
      await $.waitUntil(() => bridge.isPlayersTurn(), timeout: Timeouts.gameLoad);

      await tablePage.tapDrop();
      await tablePage.confirmDrop();

      await tablePage.assertDropPenaltyDisplayed(expectedPoints: 20);
      await tablePage.assertGameEndScreenVisible();
    },
  );

  patrolTest(
    'TC_GAME_002 — Middle drop deducts 40 penalty points',
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
      await $.waitUntil(() => bridge.isPlayersTurn(), timeout: Timeouts.gameLoad);

      // Simulate drawing one card to make this a middle drop (not first turn)
      await bridge.tapCard('top_deck');
      await bridge.dragCardToDiscard('AS');

      await tablePage.tapDrop();
      await tablePage.confirmDrop();

      await tablePage.assertDropPenaltyDisplayed(expectedPoints: 40);
    },
  );
}
