import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

class ScreenshotHelper {
  const ScreenshotHelper(this.$);
  final PatrolIntegrationTester $;

  Future<void> captureFailure(String testName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'reports/screenshots/${testName}_$timestamp.png';
    await $.tester.runAsync(() async {
      // Patrol's native screenshot capture — works on both Android and iOS
      await $.native.takeScreenshot(path);
    });
  }

  Future<void> captureStep(String stepName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await $.native.takeScreenshot('reports/screenshots/step_${stepName}_$timestamp.png');
  }
}
