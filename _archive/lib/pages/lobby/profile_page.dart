import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class ProfilePage {
  const ProfilePage(this.$);
  final PatrolIntegrationTester $;

  // ── Profile screen selectors ──────────────────────────────────────────────
  static const _editDesc        = 'Edit';
  static const _reloadDesc      = 'Reload';

  // The entire personal info card is one content-desc node:
  // "Personal Information\nMobile Number\n<phone>\nUsername\n<name>\nPractice Chips\n<balance>"
  static const _personalInfoPrefix = 'Personal Information';

  // Preferences / Account Settings row
  static const _accountSettingsRow = 'Preferences\nAccount Settings\nDelete account and Logout\nOpen';

  // ── Account Settings screen selectors ────────────────────────────────────
  static const _accountSettingsTitle = 'Account Settings';
  static const _deleteAccountDesc    = 'Delete Account';
  static const _logoutDesc           = 'Logout';
  static const _backDesc             = 'Back';

  // ── Reload Failed dialog selectors ───────────────────────────────────────
  static const _reloadFailedTitle  = 'Reload Failed';
  static const _maxChipsMessage    = 'You have maximum amount of chips.';
  static const _okButton           = 'OK\nOK';
  static const _dismissButton      = 'Dismiss';

  // ── Profile screen assertions ─────────────────────────────────────────────

  Future<void> assertProfileVisible(String username) async {
    await $.native.waitUntilVisible(
      Selector(description: username),
      timeout: Timeouts.medium,
    );
  }

  Future<void> assertPersonalInfoVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _personalInfoPrefix),
      timeout: Timeouts.short,
    );
  }

  Future<void> assertAccountSettingsRowVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _accountSettingsRow),
      timeout: Timeouts.short,
    );
  }

  // ── Profile screen actions ────────────────────────────────────────────────

  Future<void> tapEditUsername() async {
    await $.native.waitUntilVisible(
      Selector(description: _editDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _editDesc));
  }

  Future<void> tapReloadChips() async {
    await $.native.waitUntilVisible(
      Selector(description: _reloadDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _reloadDesc));
  }

  Future<void> scrollToAccountSettings() async {
    await $.native.swipe(
      from: Offset(540, 700),
      to: Offset(540, 300),
      steps: 20,
    );
  }

  Future<void> tapOpenAccountSettings() async {
    await scrollToAccountSettings();
    await $.native.waitUntilVisible(
      Selector(description: _accountSettingsRow),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _accountSettingsRow));
  }

  Future<void> tapBack() async {
    await $.native.pressBack();
  }

  // ── Reload Failed dialog ──────────────────────────────────────────────────

  Future<void> assertReloadFailedVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _reloadFailedTitle),
      timeout: Timeouts.medium,
    );
    await $.native.waitUntilVisible(
      Selector(description: _maxChipsMessage),
      timeout: Timeouts.short,
    );
  }

  Future<void> dismissReloadFailed() async {
    await $.native.waitUntilVisible(
      Selector(description: _okButton),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _okButton));
  }

  Future<bool> isReloadFailedVisible() async {
    try {
      await $.native.waitUntilVisible(
        Selector(description: _reloadFailedTitle),
        timeout: const Duration(seconds: 3),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Account Settings screen ───────────────────────────────────────────────

  Future<void> assertAccountSettingsVisible() async {
    await $.native.waitUntilVisible(
      Selector(description: _accountSettingsTitle),
      timeout: Timeouts.medium,
    );
  }

  Future<void> tapLogout() async {
    await $.native.waitUntilVisible(
      Selector(description: _logoutDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _logoutDesc));
  }

  Future<void> tapDeleteAccount() async {
    await $.native.waitUntilVisible(
      Selector(description: _deleteAccountDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _deleteAccountDesc));
  }

  Future<void> tapBackFromAccountSettings() async {
    await $.native.waitUntilVisible(
      Selector(description: _backDesc),
      timeout: Timeouts.short,
    );
    await $.native.tap(Selector(description: _backDesc));
  }
}
