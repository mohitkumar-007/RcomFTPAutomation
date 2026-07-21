import 'package:patrol/patrol.dart';

class DeepLinkHelper {
  const DeepLinkHelper(this.$);
  final PatrolIntegrationTester $;

  Future<void> openDeepLink(String url) async {
    await $.native.openUrl(url);
  }

  Future<void> openGameTable(String tableId) async {
    await openDeepLink('rummy://table/$tableId');
  }

  Future<void> openProfile() async {
    await openDeepLink('rummy://profile');
  }

  Future<void> openLobby() async {
    await openDeepLink('rummy://lobby');
  }
}
