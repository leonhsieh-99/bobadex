/// Stable codes from `POST /functions/v1/otp-auth`. Do not map provider strings in UI.
enum OtpAuthCode {
  otpSent,
  success,
  invalidIdentifier,
  unknownUser,
  phoneNotLinked,
  phoneAlreadyInUse,
  phoneLinkPending,
  phoneLinkConflict,
  invalidOtp,
  otpExpired,
  rateLimited,
  authRequired,
  configRequired,
  authError;

  static const _byName = {
    'OTP_SENT': OtpAuthCode.otpSent,
    'SUCCESS': OtpAuthCode.success,
    'INVALID_IDENTIFIER': OtpAuthCode.invalidIdentifier,
    'UNKNOWN_USER': OtpAuthCode.unknownUser,
    'PHONE_NOT_LINKED': OtpAuthCode.phoneNotLinked,
    'PHONE_ALREADY_IN_USE': OtpAuthCode.phoneAlreadyInUse,
    'PHONE_LINK_PENDING': OtpAuthCode.phoneLinkPending,
    'PHONE_LINK_CONFLICT': OtpAuthCode.phoneLinkConflict,
    'INVALID_OTP': OtpAuthCode.invalidOtp,
    'OTP_EXPIRED': OtpAuthCode.otpExpired,
    'RATE_LIMITED': OtpAuthCode.rateLimited,
    'AUTH_REQUIRED': OtpAuthCode.authRequired,
    'CONFIG_REQUIRED': OtpAuthCode.configRequired,
    'AUTH_ERROR': OtpAuthCode.authError,
  };

  static OtpAuthCode parse(String? raw) =>
      _byName[raw] ?? OtpAuthCode.authError;

  String get wire => switch (this) {
        OtpAuthCode.otpSent => 'OTP_SENT',
        OtpAuthCode.success => 'SUCCESS',
        OtpAuthCode.invalidIdentifier => 'INVALID_IDENTIFIER',
        OtpAuthCode.unknownUser => 'UNKNOWN_USER',
        OtpAuthCode.phoneNotLinked => 'PHONE_NOT_LINKED',
        OtpAuthCode.phoneAlreadyInUse => 'PHONE_ALREADY_IN_USE',
        OtpAuthCode.phoneLinkPending => 'PHONE_LINK_PENDING',
        OtpAuthCode.phoneLinkConflict => 'PHONE_LINK_CONFLICT',
        OtpAuthCode.invalidOtp => 'INVALID_OTP',
        OtpAuthCode.otpExpired => 'OTP_EXPIRED',
        OtpAuthCode.rateLimited => 'RATE_LIMITED',
        OtpAuthCode.authRequired => 'AUTH_REQUIRED',
        OtpAuthCode.configRequired => 'CONFIG_REQUIRED',
        OtpAuthCode.authError => 'AUTH_ERROR',
      };
}

class OtpAuthException implements Exception {
  final OtpAuthCode code;
  const OtpAuthException(this.code);

  @override
  String toString() => 'OtpAuthException(${code.wire})';
}

class OtpLoginTokens {
  final String userId;
  final String accessToken;
  final String refreshToken;

  const OtpLoginTokens({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });
}

class OtpPhoneLinkResult {
  final String userId;
  final String phone;

  const OtpPhoneLinkResult({required this.userId, required this.phone});
}

/// Pulls tokens from an otp-auth SUCCESS payload without keeping the rest of the session.
OtpLoginTokens parseOtpLoginSuccess(Map<String, dynamic> payload) {
  if (OtpAuthCode.parse(payload['code'] as String?) != OtpAuthCode.success) {
    throw OtpAuthException(OtpAuthCode.parse(payload['code'] as String?));
  }
  final userId = payload['user_id'];
  final session = payload['session'];
  if (userId is! String || userId.isEmpty) {
    throw const OtpAuthException(OtpAuthCode.authError);
  }
  if (session is! Map) {
    throw const OtpAuthException(OtpAuthCode.authError);
  }
  final sessionMap = Map<String, dynamic>.from(session);
  final access = sessionMap['access_token'];
  final refresh = sessionMap['refresh_token'];
  if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
    throw const OtpAuthException(OtpAuthCode.authError);
  }
  return OtpLoginTokens(userId: userId, accessToken: access, refreshToken: refresh);
}

OtpPhoneLinkResult parseOtpPhoneLinkSuccess(Map<String, dynamic> payload) {
  if (OtpAuthCode.parse(payload['code'] as String?) != OtpAuthCode.success) {
    throw OtpAuthException(OtpAuthCode.parse(payload['code'] as String?));
  }
  final userId = payload['user_id'];
  final phone = payload['phone'];
  if (userId is! String || userId.isEmpty || phone is! String || phone.isEmpty) {
    throw const OtpAuthException(OtpAuthCode.authError);
  }
  return OtpPhoneLinkResult(userId: userId, phone: phone);
}
