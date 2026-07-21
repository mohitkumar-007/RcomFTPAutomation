import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class ToastComponent {
  const ToastComponent(this.$);
  final PatrolIntegrationTester $;

  Future<void> assertToastVisible(String message) async {
    final finder = $(find.text(message));
    await finder.waitUntilVisible(timeout: Timeouts.medium);
    expect(finder, findsOneWidget);
  }

  Future<bool> isToastVisible(String message) async {
    try {
      await $(find.text(message)).waitUntilVisible(timeout: Timeouts.short);
      return true;
    } catch (_) {
      return false;
    }
  }
}
