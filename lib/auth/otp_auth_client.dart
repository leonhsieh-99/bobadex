import 'dart:convert';

import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpFunctionResponse {
  final int status;
  final Map<String, dynamic> body;
  const OtpFunctionResponse({required this.status, required this.body});
}

typedef OtpFunctionInvoker = Future<OtpFunctionResponse> Function({
  required Map<String, dynamic> body,
  Map<String, String>? headers,
});

Map<String, dynamic> mapFromUnknown(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return {};
}

Map<String, dynamic> _otpBodyFromException(FunctionException e) {
  final fromDetails = mapFromUnknown(e.details);
  if (fromDetails['code'] is String) return fromDetails;
  final fromReason = mapFromUnknown(e.reasonPhrase);
  if (fromReason['code'] is String) return fromReason;
  if (e.status == 429) return {'code': 'RATE_LIMITED'};
  return fromDetails;
}

OtpFunctionInvoker supabaseOtpInvoker(SupabaseClient client) {
  return ({required Map<String, dynamic> body, Map<String, String>? headers}) async {
    try {
      final res = await client.functions.invoke(
        'otp-auth',
        body: body,
        headers: headers,
      );
      return OtpFunctionResponse(
        status: res.status,
        body: mapFromUnknown(res.data),
      );
    } on FunctionException catch (e) {
      return OtpFunctionResponse(
        status: e.status,
        body: _otpBodyFromException(e),
      );
    }
  };
}

class OtpAuthClient {
  OtpAuthClient({
    OtpFunctionInvoker? invoke,
    GoTrueClient? auth,
    Future<void> Function(OtpLoginTokens tokens)? applySession,
    String? Function()? accessToken,
  })  : _invoke = invoke,
        _auth = auth,
        _applySession = applySession,
        _accessToken = accessToken;

  final OtpFunctionInvoker? _invoke;
  final GoTrueClient? _auth;
  final Future<void> Function(OtpLoginTokens tokens)? _applySession;
  final String? Function()? _accessToken;

  OtpFunctionInvoker get invoke =>
      _invoke ?? supabaseOtpInvoker(Supabase.instance.client);

  GoTrueClient get auth => _auth ?? Supabase.instance.client.auth;

  Future<OtpAuthCode> requestEmailLoginOtp(String email) async {
    return _expectSent({'action': 'requestEmailLoginOtp', 'email': email});
  }

  Future<OtpLoginTokens> verifyEmailLoginOtp({
    required String email,
    required String code,
  }) async {
    final payload = await _call({'action': 'verifyEmailLoginOtp', 'email': email, 'code': code});
    return parseOtpLoginSuccess(payload);
  }

  Future<OtpAuthCode> requestPhoneLoginOtp(String phone) async {
    return _expectSent(
      {'action': 'requestPhoneLoginOtp', 'phone': phone},
      phoneDelivery: true,
    );
  }

  Future<OtpLoginTokens> verifyPhoneLoginOtp({
    required String phone,
    required String code,
  }) async {
    final payload = await _call({'action': 'verifyPhoneLoginOtp', 'phone': phone, 'code': code});
    return parseOtpLoginSuccess(payload);
  }

  Future<OtpAuthCode> requestPhoneLink(String phone) async {
    return _expectSent(
      {'action': 'requestPhoneLink', 'phone': phone},
      authenticated: true,
      phoneDelivery: true,
    );
  }

  Future<OtpPhoneLinkResult> verifyPhoneLink({
    required String phone,
    required String code,
  }) async {
    final payload = await _call(
      {'action': 'verifyPhoneLink', 'phone': phone, 'code': code},
      authenticated: true,
    );
    return parseOtpPhoneLinkSuccess(payload);
  }

  Future<void> establishLoginSession(OtpLoginTokens tokens) async {
    if (tokens.userId.isEmpty ||
        tokens.accessToken.isEmpty ||
        tokens.refreshToken.isEmpty) {
      throw const OtpAuthException(OtpAuthCode.authError);
    }
    if (_applySession != null) {
      await _applySession(tokens);
      return;
    }
    await auth.setSession(tokens.refreshToken, accessToken: tokens.accessToken);
    final uid = auth.currentUser?.id;
    if (uid != tokens.userId) {
      await auth.signOut();
      throw const OtpAuthException(OtpAuthCode.authError);
    }
  }

  Future<Map<String, String>?> _authHeaders() async {
    if (_accessToken != null) {
      final token = _accessToken();
      if (token == null || token.isEmpty) return null;
      return {'Authorization': 'Bearer $token'};
    }
    var session = auth.currentSession;
    if (session == null) return null;
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (expiry.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
        await auth.refreshSession();
        session = auth.currentSession;
      }
    }
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Future<OtpAuthCode> _expectSent(
    Map<String, dynamic> body, {
    bool authenticated = false,
    bool phoneDelivery = false,
  }) async {
    try {
      final payload = await _call(body, authenticated: authenticated);
      final code = OtpAuthCode.parse(payload['code'] as String?);
      if (code != OtpAuthCode.otpSent && code != OtpAuthCode.success) {
        throw OtpAuthException(code);
      }
      return code;
    } on OtpAuthException catch (e) {
      if (phoneDelivery && e.code == OtpAuthCode.authError) {
        throw const OtpAuthException(OtpAuthCode.configRequired);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _call(
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    Map<String, String>? headers;
    if (authenticated) {
      headers = await _authHeaders();
      if (headers == null) {
        throw const OtpAuthException(OtpAuthCode.authRequired);
      }
    }

    var response = await invoke(body: body, headers: headers);
    var code = OtpAuthCode.parse(response.body['code'] as String?);

    if (authenticated && code == OtpAuthCode.authRequired) {
      await auth.refreshSession();
      headers = await _authHeaders();
      if (headers == null) {
        throw const OtpAuthException(OtpAuthCode.authRequired);
      }
      response = await invoke(body: body, headers: headers);
      code = OtpAuthCode.parse(response.body['code'] as String?);
    }

    if (code != OtpAuthCode.otpSent && code != OtpAuthCode.success) {
      throw OtpAuthException(code);
    }
    return response.body;
  }
}
