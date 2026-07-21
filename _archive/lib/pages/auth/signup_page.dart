import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../../config/test_constants.dart';
import '../../components/common/toast_component.dart';

class SignupPage {
  const SignupPage(this.$);
  final PatrolIntegrationTester $;

  PatrolFinder get _usernameField   => $('signupUsernameField');
  PatrolFinder get _emailField      => $('signupEmailField');
  PatrolFinder get _signupButton    => $('signupSubmitButton');
  PatrolFinder get _termsCheckbox   => $('termsCheckbox');

  Future<void> enterUsername(String username) async {
    await _usernameField.waitUntilVisible(timeout: Timeouts.medium);
    await _usernameField.enterText(username);
    await $.tester.testTextInput.receiveAction(TextInputAction.next);
  }

  Future<void> enterEmail(String email) async {
    await _emailField.waitUntilVisible(timeout: Timeouts.short);
    await _emailField.enterText(email);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
  }

  Future<void> acceptTerms() async {
    await _termsCheckbox.waitUntilVisible(timeout: Timeouts.short);
    await _termsCheckbox.tap();
  }

  Future<void> submitSignup() async {
    await _signupButton.waitUntilVisible(timeout: Timeouts.short);
    await _signupButton.tap();
  }

  Future<void> completeSignup({
    required String username,
    required String email,
  }) async {
    await enterUsername(username);
    await enterEmail(email);
    await acceptTerms();
    await submitSignup();
    await ToastComponent($).assertToastVisible('Account created successfully');
  }

  Future<void> assertValidationError(String fieldKey, String message) async {
    await $(find.text(message)).waitUntilVisible(timeout: Timeouts.short);
    expect($(find.text(message)), findsOneWidget);
  }
}
