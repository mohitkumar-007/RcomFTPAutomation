abstract final class Timeouts {
  static const Duration short    = Duration(seconds: 5);
  static const Duration medium   = Duration(seconds: 15);
  static const Duration long     = Duration(seconds: 30);
  static const Duration gameLoad = Duration(seconds: 45);
}

abstract final class Keys {
  // Auth
  static const phoneInput      = 'phoneInputField';
  static const otpInput        = 'otpInputField';
  static const sendOtpButton   = 'sendOtpButton';
  static const verifyOtpButton = 'verifyOtpButton';
  static const resendOtpButton = 'resendOtpButton';

  // Lobby / Profile
  static const profileButton       = 'profileButton';
  static const editAvatarButton    = 'editAvatarButton';
  static const usernameField       = 'usernameField';
  static const saveProfileButton   = 'saveProfileButton';
  static const walletBalanceText   = 'walletBalanceText';
  static const logoutButton        = 'logoutButton';
  static const deleteAccountButton = 'deleteAccountButton';
  static const backButton          = 'backButton';

  // Game Selection
  static const pointsRummyCard = 'gameCard_points_rummy';
  static const poolRummyCard   = 'gameCard_pool_rummy';
  static const dealRummyCard   = 'gameCard_deal_rummy';
  static const joinTableButton = 'joinTableButton';

  // Gameplay
  static const dropButton        = 'dropButton';
  static const declareButton     = 'declareButton';
  static const confirmDropButton = 'confirmDropButton';
  static const declareConfirm    = 'declareConfirmButton';
}
