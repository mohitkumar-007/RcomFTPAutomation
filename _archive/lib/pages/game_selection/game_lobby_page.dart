import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

enum RummyVariant { points, pool, deal }

class GameLobbyPage {
  const GameLobbyPage(this.$);
  final PatrolIntegrationTester $;

  static const _variantKeyMap = {
    RummyVariant.points: Keys.pointsRummyCard,
    RummyVariant.pool:   Keys.poolRummyCard,
    RummyVariant.deal:   Keys.dealRummyCard,
  };

  Future<void> selectVariant(RummyVariant variant) async {
    final key = _variantKeyMap[variant]!;
    final card = $(key);
    await card.waitUntilVisible(timeout: Timeouts.medium);
    await card.tap();
  }

  Future<void> selectTableAndJoin({
    required RummyVariant variant,
    int tableIndex = 0,
  }) async {
    await selectVariant(variant);
    // Table list uses ValueKey convention: table_row_0, table_row_1 ...
    final tableRow = $('table_row_$tableIndex');
    await tableRow.waitUntilVisible(timeout: Timeouts.medium);
    await tableRow.tap();
    await $(#joinTableButton).waitUntilVisible(timeout: Timeouts.short);
    await $(#joinTableButton).tap();
  }
}
