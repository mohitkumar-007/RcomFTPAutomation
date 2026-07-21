import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class DialogComponent {
  const DialogComponent(this.$);
  final PatrolIntegrationTester $;

  Future<void> confirmNativeDialog({required String buttonLabel}) async {
    if (await $.native.isPermissionDialogVisible(timeout: Timeouts.short)) {
      await $.native.tapAlertDialogButton(buttonLabel);
    }
  }

  Future<void> tapFlutterDialogButton(String buttonLabel) async {
    final button = $(find.text(buttonLabel));
    await button.waitUntilVisible(timeout: Timeouts.short);
    await button.tap();
  }

  Future<void> dismissIfVisible() async {
    try {
      if (await $.native.isPermissionDialogVisible(timeout: const Duration(seconds: 2))) {
        await $.native.tapAlertDialogButton('Dismiss');
      }
    } catch (_) {
      // No dialog visible — safe to continue
    }
  }
}
