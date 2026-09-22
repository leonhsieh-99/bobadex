import 'package:bobadex/auth/otp_auth_codes.dart';

String messageForOtpCode(OtpAuthCode code) {
  return switch (code) {
    OtpAuthCode.otpSent => 'We sent a verification code.',
    OtpAuthCode.success => 'You are signed in.',
    OtpAuthCode.invalidIdentifier => 'Enter a valid email.',
    OtpAuthCode.unknownUser =>
      'No account uses that email. Sign up to create one.',
    OtpAuthCode.emailAlreadyInUse =>
      'That email is already used by an account.',
    OtpAuthCode.emailUnchanged => 'That is already your email.',
    OtpAuthCode.currentEmailMismatch =>
      'Enter the email currently on this account.',
    OtpAuthCode.usernameTaken => 'That username is taken.',
    OtpAuthCode.phoneNotLinked =>
      'This phone is not linked to an account. Sign in with email.',
    OtpAuthCode.phoneAlreadyInUse =>
      'That phone number is already used by another account.',
    OtpAuthCode.phoneLinkPending =>
      'Another phone verification is still pending. Finish or wait, then try again.',
    OtpAuthCode.phoneLinkConflict =>
      'Phone linking could not be completed safely. Wait a bit, then try again.',
    OtpAuthCode.invalidOtp => 'That code is incorrect.',
    OtpAuthCode.otpExpired => 'That code has expired. Request a new one.',
    OtpAuthCode.rateLimited =>
      'Too many codes were sent. Wait a minute, then try again.',
    OtpAuthCode.authRequired => 'Sign in again to change your email.',
    OtpAuthCode.configRequired =>
      'Could not send email. Check SMTP settings, then try again.',
    OtpAuthCode.authError => 'Something went wrong. Please try again.',
  };
}

/// Quiet hint under the code field. Keep this secondary to the "code sent" line.
const otpInboxHint = 'Can take a few seconds. Check spam if you don\'t see it.';

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
      return 'Too many codes were sent. Try again in ${formatOtpWaitDuration(secondsLeft)}.';
    }
    return 'Too many codes were sent. Wait a minute, then try again.';
  }
  if (secondsLeft > 0) {
    return 'You can request another code in ${formatOtpWaitDuration(secondsLeft)}.';
  }
  return 'You can request a new code now.';
}
