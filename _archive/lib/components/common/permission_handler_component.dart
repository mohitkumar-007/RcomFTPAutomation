import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class PermissionHandlerComponent {
  const PermissionHandlerComponent(this.$);
  final PatrolIntegrationTester $;

  /// Dismisses all permission dialogs that appear at app launch
  /// (notifications, location, contacts, etc.).
  Future<void> dismissStartupPermissions() async {
    const permissionsToHandle = [
      'Allow',
      'While Using the App',
      'Don\'t Allow',
      'Deny',
    ];

    // Poll briefly to catch staggered permission prompts
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        if (await $.native.isPermissionDialogVisible(timeout: const Duration(seconds: 3))) {
          await $.native.denyPermission();
        }
      } catch (_) {
        break;
      }
    }
  }

  Future<void> grantNotificationPermission() async {
    if (await $.native.isPermissionDialogVisible(timeout: Timeouts.short)) {
      await $.native.grantPermissionWhenInUse();
    }
  }
}
