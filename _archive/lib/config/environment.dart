abstract final class Environment {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://qa.rummy.internal',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://qa.rummy.internal/ws/game',
  );
  static const bool useMockGameServer = bool.fromEnvironment(
    'MOCK_GAME_SERVER',
    defaultValue: false,
  );
  static const String testPhone = String.fromEnvironment(
    'TEST_PHONE',
    defaultValue: '+919000000001',
  );

  // Stage environment always accepts this OTP for any phone number.
  // No dart-define needed — hardcoded by the backend team for QA builds.
  static const String stageOtp = '123456';
}
