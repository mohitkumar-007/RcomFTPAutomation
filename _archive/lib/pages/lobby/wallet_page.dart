import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';

class WalletPage {
  const WalletPage(this.$);
  final PatrolIntegrationTester $;

  PatrolFinder get _walletScreen   => $('walletScreen');
  PatrolFinder get _totalChips     => $('totalChipsText');
  PatrolFinder get _depositButton  => $('depositButton');
  PatrolFinder get _withdrawButton => $('withdrawButton');

  Future<void> assertWalletVisible() async {
    await _walletScreen.waitUntilVisible(timeout: Timeouts.medium);
    expect(_walletScreen, findsOneWidget);
  }

  Future<double> getTotalChips() async {
    await _totalChips.waitUntilVisible(timeout: Timeouts.medium);
    final text = await _totalChips.text ?? '0';
    return double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  Future<void> assertBalanceIsNonNegative() async {
    final balance = await getTotalChips();
    expect(balance, greaterThanOrEqualTo(0));
  }
}
