import 'dart:convert';
import 'dart:math';

import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:bobadex/auth/phone_e164.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Passwordless email signup and email change.
///
/// Login stays on `otp-auth`. These account actions use Auth email OTP so we
/// do not replace that function. Google/Apple can later attach identities to
/// the same Auth user without changing this UI.
class EmailAccountAuth {
  EmailAccountAuth({SupabaseClient? client, GoTrueClient? auth})
    : _client = client,
      _auth = auth;

  final SupabaseClient? _client;
  final GoTrueClient? _auth;

  SupabaseClient get client => _client ?? Supabase.instance.client;
  GoTrueClient get auth => _auth ?? client.auth;

  Future<OtpAuthCode> requestSignup({
    required String email,
    required String username,
    required String displayName,
  }) async {
    final normalized = emailToOtpIdentifier(email);
    if (normalized == null) {
      throw const OtpAuthException(OtpAuthCode.invalidIdentifier);
    }
    final nameError = Validators.validateDisplayName(displayName);
    if (nameError != null) {
      throw const OtpAuthException(OtpAuthCode.invalidIdentifier);
    }
    final usernameError = Validators.validateUsername(username);
    if (usernameError != null) {
      throw const OtpAuthException(OtpAuthCode.invalidIdentifier);
    }

    final usernameTaken = await client.rpc(
      'username_exists',
      params: {'input_username': username.trim()},
    );
    if (usernameTaken == true) {
      throw const OtpAuthException(OtpAuthCode.usernameTaken);
    }

    final emailTaken =
        await client.rpc('email_exists', params: {'input_email': normalized})
            as bool? ??
        false;
    if (emailTaken) {
      throw const OtpAuthException(OtpAuthCode.emailAlreadyInUse);
    }

    try {
      final response = await auth.signUp(
        email: normalized,
        password: _randomSecret(),
        data: {'username': username.trim(), 'display_name': displayName.trim()},
        emailRedirectTo: 'bobadex://login',
      );
      if (response.session != null) return OtpAuthCode.success;
      return OtpAuthCode.otpSent;
    } on AuthException catch (e) {
      throw OtpAuthException(_mapAuth(e));
    }
  }

  Future<void> verifySignup({
    required String email,
    required String code,
  }) async {
    final normalized = emailToOtpIdentifier(email);
    if (normalized == null || !isOtpCode(code)) {
      throw const OtpAuthException(OtpAuthCode.invalidOtp);
    }
    try {
      final response = await auth.verifyOTP(
        type: OtpType.signup,
        email: normalized,
        token: code,
      );
      if (response.session == null) {
        throw const OtpAuthException(OtpAuthCode.authError);
      }
    } on AuthException catch (e) {
      throw OtpAuthException(_mapAuth(e));
    }
  }

  Future<OtpAuthCode> requestEmailChange(String email) async {
    final normalized = emailToOtpIdentifier(email);
    if (normalized == null) {
      throw const OtpAuthException(OtpAuthCode.invalidIdentifier);
    }
    final current = auth.currentUser;
    if (current == null) {
      throw const OtpAuthException(OtpAuthCode.authRequired);
    }
    final currentEmail = current.email?.trim().toLowerCase();
    if (currentEmail == normalized) {
      throw const OtpAuthException(OtpAuthCode.emailUnchanged);
    }

    final emailTaken =
        await client.rpc('email_exists', params: {'input_email': normalized})
            as bool? ??
        false;
    if (emailTaken) {
      throw const OtpAuthException(OtpAuthCode.emailAlreadyInUse);
    }

    try {
      await auth.updateUser(UserAttributes(email: normalized));
      return OtpAuthCode.otpSent;
    } on AuthException catch (e) {
      throw OtpAuthException(_mapAuth(e));
    }
  }

  Future<void> verifyEmailChange({
    required String email,
    required String code,
  }) async {
    final normalized = emailToOtpIdentifier(email);
    if (normalized == null || !isOtpCode(code)) {
      throw const OtpAuthException(OtpAuthCode.invalidOtp);
    }
    if (auth.currentUser == null) {
      throw const OtpAuthException(OtpAuthCode.authRequired);
    }
    try {
      final response = await auth.verifyOTP(
        type: OtpType.emailChange,
        email: normalized,
        token: code,
      );
      if (response.user == null) {
        throw const OtpAuthException(OtpAuthCode.authError);
      }
      await auth.refreshSession();
    } on AuthException catch (e) {
      throw OtpAuthException(_mapAuth(e));
    }
  }

  String _randomSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  OtpAuthCode _mapAuth(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('rate') || message.contains('too many')) {
      return OtpAuthCode.rateLimited;
    }
    if (message.contains('expired')) return OtpAuthCode.otpExpired;
    if (message.contains('already') || message.contains('registered')) {
      return OtpAuthCode.emailAlreadyInUse;
    }
    if (message.contains('smtp') ||
        message.contains('mail') ||
        message.contains('535') ||
        message.contains('550') ||
        message.contains('relay')) {
      return OtpAuthCode.configRequired;
    }
    if (message.contains('invalid') &&
        (message.contains('token') ||
            message.contains('otp') ||
            message.contains('code'))) {
      return OtpAuthCode.invalidOtp;
    }
    return OtpAuthCode.authError;
  }
}
