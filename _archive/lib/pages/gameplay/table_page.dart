import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../bridges/flame_game_bridge.dart';
import '../../components/common/dialog_component.dart';
import '../../config/test_constants.dart';

class TablePage {
  TablePage(this.$) : _bridge = FlameGameBridge();
  final PatrolIntegrationTester $;
  final FlameGameBridge _bridge;

  PatrolFinder get _tableScreen       => $('gameTableScreen');
  PatrolFinder get _dropButton        => $(#dropButton);
  PatrolFinder get _confirmDropButton => $(#confirmDropButton);
  PatrolFinder get _declareButton     => $(#declareButton);
  PatrolFinder get _declareConfirm    => $(#declareConfirmButton);
  PatrolFinder get _gameOverScreen    => $('gameOverScreen');
  PatrolFinder get _penaltyText       => $('penaltyPointsText');
  PatrolFinder get _wrongDeclareText  => $('wrongDeclarationText');

  Future<void> waitForTableToLoad() async {
    await _tableScreen.waitUntilVisible(timeout: Timeouts.gameLoad);
    expect(_tableScreen, findsOneWidget);
  }

  // Uses semantic overlay widget tagged over the Flame card sprite
  Future<void> tapCard(String cardId) async {
    final cardFinder = $('flame_card_$cardId');
    if (await cardFinder.exists) {
      await cardFinder.tap();
    } else {
      // Fall back to bridge for environments without overlay support
      await _bridge.tapCard(cardId);
    }
  }

  Future<void> dragCardToDiscard(String cardId) async {
    await _bridge.dragCardToDiscard(cardId);
  }

  Future<void> tapDrop() async {
    await _dropButton.waitUntilVisible(timeout: Timeouts.medium);
    await _dropButton.tap();
  }

  Future<void> confirmDrop() async {
    await _confirmDropButton.waitUntilVisible(timeout: Timeouts.short);
    await _confirmDropButton.tap();
  }

  Future<void> tapDeclare() async {
    await _declareButton.waitUntilVisible(timeout: Timeouts.medium);
    await _declareButton.tap();
  }

  Future<void> confirmDeclare() async {
    await _declareConfirm.waitUntilVisible(timeout: Timeouts.short);
    await _declareConfirm.tap();
  }

  Future<void> assertDropPenaltyDisplayed({required int expectedPoints}) async {
    await _gameOverScreen.waitUntilVisible(timeout: Timeouts.long);
    final penaltyFinder = $(find.text('$expectedPoints'));
    await penaltyFinder.waitUntilVisible(timeout: Timeouts.short);
    expect(penaltyFinder, findsOneWidget);
  }

  Future<void> assertWrongDeclarationPenalty({required int expectedPoints}) async {
    await _wrongDeclareText.waitUntilVisible(timeout: Timeouts.medium);
    await $(find.text('$expectedPoints points deducted'))
        .waitUntilVisible(timeout: Timeouts.short);
  }

  Future<void> assertGameEndScreenVisible() async {
    await _gameOverScreen.waitUntilVisible(timeout: Timeouts.long);
    expect(_gameOverScreen, findsOneWidget);
  }
}
