import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../config/test_constants.dart';

class AssertionHelper {
  const AssertionHelper(this.$);
  final PatrolIntegrationTester $;

  Future<void> assertTextVisible(String text, {Duration? timeout}) async {
    final finder = $(find.text(text));
    await finder.waitUntilVisible(timeout: timeout ?? Timeouts.short);
    expect(finder, findsOneWidget);
  }

  Future<void> assertKeyVisible(String key, {Duration? timeout}) async {
    final finder = $(key);
    await finder.waitUntilVisible(timeout: timeout ?? Timeouts.short);
    expect(finder, findsOneWidget);
  }

  Future<void> assertKeyAbsent(String key) async {
    final finder = $(key);
    expect(finder, findsNothing);
  }

  Future<void> assertNumericAndNonNegative(String rawText) async {
    final parsed = double.tryParse(rawText.replaceAll(RegExp(r'[^\d.]'), ''));
    expect(parsed, isNotNull, reason: '"$rawText" is not numeric');
    expect(parsed, greaterThanOrEqualTo(0));
  }
}
