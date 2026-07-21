import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class SplashPage {
  const SplashPage(this.$);
  final PatrolIntegrationTester $;

  Future<void> waitForSplashToComplete() async {
    // Splash hides when the logo finishes animating; login screen appears
    await $(#phoneInputField).waitUntilVisible(timeout: Timeouts.long);
  }
}
