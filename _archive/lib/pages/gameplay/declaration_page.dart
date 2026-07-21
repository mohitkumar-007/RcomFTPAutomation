import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class DeclarationPage {
  const DeclarationPage(this.$);
  final PatrolIntegrationTester $;

  PatrolFinder get _declarationScreen => $('declarationScreen');
  PatrolFinder get _submitButton      => $('submitDeclarationButton');
  PatrolFinder get _validBadge        => $('validDeclarationBadge');
  PatrolFinder get _invalidBadge      => $('invalidDeclarationBadge');

  Future<void> assertDeclarationScreenVisible() async {
    await _declarationScreen.waitUntilVisible(timeout: Timeouts.medium);
    expect(_declarationScreen, findsOneWidget);
  }

  Future<void> arrangeGroup({required int groupIndex, required List<String> cardIds}) async {
    for (final cardId in cardIds) {
      final card = $('declCard_$cardId');
      await card.waitUntilVisible(timeout: Timeouts.short);
      final groupTarget = $('declGroup_$groupIndex');
      await $.tester.drag(card.finder, $.tester.getCenter(groupTarget.finder));
      await $.tester.pump();
    }
  }

  Future<void> submitDeclaration() async {
    await _submitButton.waitUntilVisible(timeout: Timeouts.short);
    await _submitButton.tap();
  }

  Future<void> assertValidDeclaration() async {
    await _validBadge.waitUntilVisible(timeout: Timeouts.medium);
    expect(_validBadge, findsOneWidget);
  }

  Future<void> assertInvalidDeclaration() async {
    await _invalidBadge.waitUntilVisible(timeout: Timeouts.medium);
    expect(_invalidBadge, findsOneWidget);
  }
}
