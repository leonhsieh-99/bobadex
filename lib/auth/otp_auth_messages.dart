import 'package:bobadex/auth/otp_auth_codes.dart';

String messageForOtpCode(OtpAuthCode code) {
  return switch (code) {
    OtpAuthCode.otpSent => 'We sent a verification code.',
    OtpAuthCode.success => 'You are signed in.',
    OtpAuthCode.invalidIdentifier => 'Enter a valid email.',
    OtpAuthCode.unknownUser =>
      'No account uses that email. Sign up, or try password login.',
    OtpAuthCode.phoneNotLinked =>
      'This phone is not linked to an account. Sign in with email or password.',
    OtpAuthCode.phoneAlreadyInUse =>
      'That phone number is already used by another account.',
    OtpAuthCode.phoneLinkPending =>
      'Another phone verification is still pending. Finish or wait, then try again.',
    OtpAuthCode.phoneLinkConflict =>
      'Phone linking could not be completed safely. Wait a bit, then try again.',
    OtpAuthCode.invalidOtp => 'That code is incorrect.',
    OtpAuthCode.otpExpired => 'That code has expired. Request a new one.',
    OtpAuthCode.rateLimited =>
      'Too many codes were sent. Use password login, or wait up to an hour.',
    OtpAuthCode.authRequired => 'Sign in again before changing your phone number.',
    OtpAuthCode.configRequired =>
      'Verification codes cannot be sent right now. Use password login, or try again later.',
    OtpAuthCode.authError => 'Something went wrong. Please try again.',
  };
}

String maskPhone(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '••••';
  final last4 = digits.substring(digits.length - 4);
  return '+••••$last4';
}

String formatOtpWaitDuration(int secondsLeft) {
  if (secondsLeft >= 3600) return 'up to 1 hour';
  if (secondsLeft >= 90) return '${(secondsLeft / 60).ceil()} min';
  return '${secondsLeft}s';
}

String otpWaitCopy(int secondsLeft, {bool rateLimited = false}) {
  if (rateLimited) {
    if (secondsLeft > 0) {
      return 'Too many codes were sent. Use password login, or try again in ${formatOtpWaitDuration(secondsLeft)}.';
    }
    return 'Too many codes were sent. Use password login, or wait up to an hour.';
  }
  if (secondsLeft > 0) {
    return 'You can request another code in ${formatOtpWaitDuration(secondsLeft)}.';
  }
  return 'You can request a new code now.';
}
