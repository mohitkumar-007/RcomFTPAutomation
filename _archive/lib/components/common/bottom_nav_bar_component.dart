import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

enum NavTab { lobby, tournaments, profile, wallet }

class BottomNavBarComponent {
  const BottomNavBarComponent(this.$);
  final PatrolIntegrationTester $;

  static const _tabKeyMap = {
    NavTab.lobby:       'navTab_lobby',
    NavTab.tournaments: 'navTab_tournaments',
    NavTab.profile:     'navTab_profile',
    NavTab.wallet:      'navTab_wallet',
  };

  Future<void> navigateTo(NavTab tab) async {
    final key = _tabKeyMap[tab]!;
    final finder = $(key);
    await finder.waitUntilVisible(timeout: Timeouts.medium);
    await finder.tap();
  }
}
