import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class ScoreboardComponent {
  const ScoreboardComponent(this.$);
  final PatrolIntegrationTester $;

  Future<int> readPlayerScore(String playerId) async {
    final scoreFinder = $('playerScore_$playerId');
    await scoreFinder.waitUntilVisible(timeout: Timeouts.medium);
    final text = await scoreFinder.text ?? '0';
    return int.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }

  Future<void> assertScoreboardVisible() async {
    await $('scoreboard').waitUntilVisible(timeout: Timeouts.long);
    expect($('scoreboard'), findsOneWidget);
  }

  Future<void> assertWinnerLabel(String playerName) async {
    await $(find.text('Winner: $playerName')).waitUntilVisible(timeout: Timeouts.medium);
  }
}
