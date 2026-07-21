import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class LobbyPage {
  const LobbyPage(this.$);
  final PatrolIntegrationTester $;

  // ── Selectors ─────────────────────────────────────────────────────────────
  static const _practiceDesc    = 'Practice';
  static const _tournamentsDesc = 'Tournaments';
  static const _usernameInMenu  = 'HolyLeader255'; // dynamic per test account
  static const _chipsLabel      = 'Chips';
  static const _contactUsDesc   = 'Contact Us';
  static const _tncDesc         = 'Terms & Conditions';
  static const _privacyDesc     = 'Privacy Policy';

  // ── Assertions ────────────────────────────────────────────────────────────

  Future<void> assertLobbyVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _practiceDesc),
      timeout: Timeouts.long,
    );
  }

  Future<void> assertUsernameVisible(String username) async {
    await $.native.waitUntilVisible(
      Selector(description: username),
      timeout: Timeouts.short,
    );
  }

  Future<void> assertAppVersion(String version) async {
    await $.native.waitUntilVisible(
      Selector(description: version),
      timeout: Timeouts.short,
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> tapPractice() async {
    await $.native.waitUntilVisible(
      Selector(description: _practiceDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _practiceDesc));
  }

  Future<void> tapTournaments() async {
    await $.native.waitUntilVisible(
      Selector(description: _tournamentsDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _tournamentsDesc));
  }

  Future<void> closeHamburgerMenu() async {
    await $.native.pressBack();
  }

  Future<void> tapContactUs() async {
    await $.native.waitUntilVisible(
      Selector(description: _contactUsDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _contactUsDesc));
  }

  Future<void> tapTermsAndConditions() async {
    await $.native.waitUntilVisible(
      Selector(description: _tncDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _tncDesc));
  }

  Future<void> tapPrivacyPolicy() async {
    await $.native.waitUntilVisible(
      Selector(description: _privacyDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _privacyDesc));
  }

  // ── State checks ──────────────────────────────────────────────────────────

  Future<bool> isOnLobby() async {
    try {
      await $.native.waitUntilVisible(
        Selector(description: _practiceDesc),
        timeout: Timeouts.short,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
