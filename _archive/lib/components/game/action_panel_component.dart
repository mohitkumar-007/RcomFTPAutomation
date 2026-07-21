import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class ActionPanelComponent {
  const ActionPanelComponent(this.$);
  final PatrolIntegrationTester $;

  PatrolFinder get _dropButton    => $(#dropButton);
  PatrolFinder get _declareButton => $(#declareButton);
  PatrolFinder get _sortButton    => $('sortHandButton');

  Future<void> tapDrop() async {
    await _dropButton.waitUntilVisible(timeout: Timeouts.medium);
    await _dropButton.tap();
  }

  Future<void> tapDeclare() async {
    await _declareButton.waitUntilVisible(timeout: Timeouts.medium);
    await _declareButton.tap();
  }

  Future<void> tapSort() async {
    await _sortButton.waitUntilVisible(timeout: Timeouts.short);
    await _sortButton.tap();
  }

  Future<bool> isDropEnabled() async {
    final btn = _dropButton;
    await btn.waitUntilVisible(timeout: Timeouts.short);
    final widget = $.tester.widget(btn.finder);
    return widget != null;
  }
}
