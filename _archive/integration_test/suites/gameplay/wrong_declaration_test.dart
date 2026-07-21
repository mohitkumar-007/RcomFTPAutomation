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
          'canDeclare': true,
          'hand': ['AS','KH','3S','4H','5H','6H','7D','8D','9D','10C','JC','QC','9C'],
          'joker': '2H',
          'deckCount': 8,
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
    'TC_WDECL_001 — Wrong declaration deducts 80 penalty points',
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

      // Force an invalid declaration via bridge (mixed suit, no valid sequence)
      await bridge.triggerDeclare([
        ['AS', 'KH', '3S'],   // invalid — mixed suits, not a set or sequence
        ['4H', '5H', '6H'],
        ['7D', '8D', '9D'],
        ['10C', 'JC', 'QC', '9C'],
      ]);

      await tablePage.assertWrongDeclarationPenalty(expectedPoints: 80);
    },
  );
}
