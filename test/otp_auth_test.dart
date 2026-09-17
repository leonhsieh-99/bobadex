import 'package:bobadex/auth/auth_redaction.dart';
import 'package:bobadex/auth/otp_auth_client.dart';
import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:bobadex/auth/otp_auth_messages.dart';
import 'package:bobadex/auth/phone_e164.dart';
import 'package:bobadex/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

OtpFunctionInvoker scriptedInvoker(List<OtpFunctionResponse> responses) {
  var i = 0;
  return ({required Map<String, dynamic> body, Map<String, String>? headers}) async {
    if (i >= responses.length) {
      return const OtpFunctionResponse(status: 500, body: {'code': 'AUTH_ERROR'});
    }
    return responses[i++];
  };
}

Map<String, dynamic> loginSuccess({
  required String userId,
  String access = 'access-token',
  String refresh = 'refresh-token',
}) {
  return {
    'code': 'SUCCESS',
    'user_id': userId,
    'session': {
      'access_token': access,
      'refresh_token': refresh,
      'token_type': 'bearer',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseOtpLoginSuccess', () {
    test('extracts tokens from a valid session payload', () {
      final tokens = parseOtpLoginSuccess(loginSuccess(userId: 'user-1'));
      expect(tokens.userId, 'user-1');
      expect(tokens.accessToken, 'access-token');
      expect(tokens.refreshToken, 'refresh-token');
    });

    test('rejects a malformed session', () {
      expect(
        () => parseOtpLoginSuccess({'code': 'SUCCESS', 'user_id': 'user-1'}),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.authError)),
      );
    });
  });

  group('OtpAuthClient', () {
    test('existing email can request and verify OTP then apply session', () async {
      OtpLoginTokens? applied;
      final client = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
          OtpFunctionResponse(status: 200, body: loginSuccess(userId: 'user-1')),
        ]),
        applySession: (tokens) async => applied = tokens,
      );

      await client.requestEmailLoginOtp('user@example.com');
      final tokens = await client.verifyEmailLoginOtp(email: 'user@example.com', code: '123456');
      await client.establishLoginSession(tokens);

      expect(applied?.userId, 'user-1');
      expect(applied?.accessToken, 'access-token');
    });

    test('existing linked phone can request and verify OTP', () async {
      OtpLoginTokens? applied;
      final client = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
          OtpFunctionResponse(status: 200, body: loginSuccess(userId: 'user-2')),
        ]),
        applySession: (tokens) async => applied = tokens,
      );

      await client.requestPhoneLoginOtp('+14155550123');
      final tokens = await client.verifyPhoneLoginOtp(phone: '+14155550123', code: '654321');
      await client.establishLoginSession(tokens);
      expect(applied?.userId, 'user-2');
    });

    test('unknown email does not return a session', () async {
      final client = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 404, body: {'code': 'UNKNOWN_USER'}),
        ]),
        applySession: (_) async => fail('must not establish a session'),
      );
      expect(
        () => client.requestEmailLoginOtp('missing@example.com'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.unknownUser)),
      );
    });

    test('unlinked phone does not create an account', () async {
      final client = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 404, body: {'code': 'PHONE_NOT_LINKED'}),
        ]),
        applySession: (_) async => fail('must not establish a session'),
      );
      expect(
        () => client.requestPhoneLoginOtp('+14155550999'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.phoneNotLinked)),
      );
    });

    test('invalid and expired codes fail without a session', () async {
      final invalid = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 400, body: {'code': 'INVALID_OTP'}),
        ]),
        applySession: (_) async => fail('no session'),
      );
      expect(
        () => invalid.verifyEmailLoginOtp(email: 'user@example.com', code: '000000'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.invalidOtp)),
      );

      final expired = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 400, body: {'code': 'OTP_EXPIRED'}),
        ]),
        applySession: (_) async => fail('no session'),
      );
      expect(
        () => expired.verifyEmailLoginOtp(email: 'user@example.com', code: '000000'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.otpExpired)),
      );
    });

    test('rate-limited request surfaces RATE_LIMITED', () async {
      final client = OtpAuthClient(
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 429, body: {'code': 'RATE_LIMITED'}),
        ]),
      );
      expect(
        () => client.requestEmailLoginOtp('user@example.com'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.rateLimited)),
      );
    });

    test('phone linking requires an authenticated session', () async {
      final client = OtpAuthClient(
        invoke: scriptedInvoker([]),
        accessToken: () => null,
      );
      expect(
        () => client.requestPhoneLink('+14155550123'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.authRequired)),
      );
    });

    test('phone-link success keeps the same user id and sends a bearer token', () async {
      Map<String, String>? seenHeaders;
      final client = OtpAuthClient(
        accessToken: () => 'user-jwt',
        invoke: ({required body, headers}) async {
          seenHeaders = headers;
          expect(body['action'], 'verifyPhoneLink');
          return OtpFunctionResponse(
            status: 200,
            body: {
              'code': 'SUCCESS',
              'user_id': 'same-user',
              'phone': '+14155550123',
            },
          );
        },
      );
      final result = await client.verifyPhoneLink(phone: '+14155550123', code: '123456');
      expect(result.userId, 'same-user');
      expect(result.phone, '+14155550123');
      expect(seenHeaders?['Authorization'], 'Bearer user-jwt');
    });

    test('phone SMS auth errors map to CONFIG_REQUIRED', () async {
      final client = OtpAuthClient(
        accessToken: () => 'user-jwt',
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 500, body: {'code': 'AUTH_ERROR'}),
        ]),
      );
      expect(
        () => client.requestPhoneLink('+14155550123'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.configRequired)),
      );
    });

    test('phone owned by another account fails safely', () async {
      final client = OtpAuthClient(
        accessToken: () => 'user-jwt',
        invoke: scriptedInvoker([
          const OtpFunctionResponse(status: 409, body: {'code': 'PHONE_ALREADY_IN_USE'}),
        ]),
      );
      expect(
        () => client.requestPhoneLink('+14155550123'),
        throwsA(isA<OtpAuthException>().having((e) => e.code, 'code', OtpAuthCode.phoneAlreadyInUse)),
      );
    });
  });

  group('privacy', () {
    test('OTP and session values are treated as secrets', () {
      expect(containsAuthSecrets('{"access_token":"abc"}'), isTrue);
      expect(containsAuthSecrets('refresh_token=xyz'), isTrue);
      expect(containsAuthSecrets('"code":"123456"'), isTrue);
      expect(containsAuthSecrets('shop added'), isFalse);
      expect(OtpAuthException(OtpAuthCode.invalidOtp).toString(), isNot(contains('123456')));
    });
  });

  group('phone and email helpers', () {
    test('normalizes email and parses E.164 without string concatenation', () {
      expect(emailToOtpIdentifier('  User@Example.COM '), 'user@example.com');
      expect(phoneToE164('(415) 555-0123', IsoCode.US), '+14155550123');
      expect(phoneToE164('+14155550123', IsoCode.US), '+14155550123');
      expect(isOtpCode('123456'), isTrue);
      expect(isOtpCode('12'), isFalse);
    });
  });

  group('AuthPage OTP UX', () {
    late List<Map<String, dynamic>> calls;
    late OtpLoginTokens? applied;
    late OtpAuthClient client;

    setUp(() {
      calls = [];
      applied = null;
    });

    OtpAuthClient clientWith(List<OtpFunctionResponse> responses) {
      var i = 0;
      return OtpAuthClient(
        applySession: (tokens) async => applied = tokens,
        invoke: ({required body, headers}) async {
          calls.add(body);
          if (i >= responses.length) {
            return const OtpFunctionResponse(status: 500, body: {'code': 'AUTH_ERROR'});
          }
          return responses[i++];
        },
      );
    }

    testWidgets('email OTP request and verify apply the session', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
        OtpFunctionResponse(status: 200, body: loginSuccess(userId: 'user-1')),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter the code sent to user@example.com'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(applied?.userId, 'user-1');
      expect(calls.first['action'], 'requestEmailLoginOtp');
      expect(calls.last['action'], 'verifyEmailLoginOtp');
      expect(calls.last['code'], '123456');
    });

    testWidgets('unknown email offers signup and does not create an account', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 404, body: {'code': 'UNKNOWN_USER'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'missing@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text('Create an account'), findsOneWidget);
      expect(applied, isNull);
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Send code'), findsNothing);
    });

    testWidgets('invalid code and expired code stay on the verify step', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
        const OtpFunctionResponse(status: 400, body: {'code': 'INVALID_OTP'}),
        const OtpFunctionResponse(status: 400, body: {'code': 'OTP_EXPIRED'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '000000');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(find.text('That code is incorrect.'), findsWidgets);
      expect(find.text('Verify code'), findsOneWidget);
      expect(applied, isNull);

      await tester.enterText(find.byType(TextFormField), '111111');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(find.textContaining('expired'), findsWidgets);
      expect(applied, isNull);
    });

    testWidgets('rate-limited request stays on identifier entry', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 429, body: {'code': 'RATE_LIMITED'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Send code'), findsOneWidget);
      expect(find.textContaining('Too many codes'), findsWidgets);
    });

    testWidgets('pasting a full code fills the single OTP field', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '847291');
      expect(find.text('847291'), findsOneWidget);
    });

    testWidgets('back navigation clears the code and restores identifier editing', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.byTooltip('Edit email'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Send code'), findsOneWidget);
      expect(find.textContaining('You can request another code in'), findsOneWidget);
      expect(find.text('123456'), findsNothing);
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('background and resume keep the verification identifier', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.textContaining('user@example.com'), findsOneWidget);
      expect(find.text('Verify code'), findsOneWidget);
      expect(applied, isNull);
    });

    testWidgets('malformed session response is rejected', (tester) async {
      client = clientWith([
        const OtpFunctionResponse(status: 200, body: {'code': 'OTP_SENT'}),
        const OtpFunctionResponse(status: 200, body: {'code': 'SUCCESS', 'user_id': 'user-1'}),
      ]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(applied, isNull);
      expect(find.textContaining('try again'), findsWidgets);
    });

    testWidgets('password login remains available and signup stays separate', (tester) async {
      client = clientWith([]);
      await tester.pumpWidget(MaterialApp(home: AuthPage(otpClient: client)));
      expect(find.text('Send code'), findsOneWidget);
      await tester.tap(find.text('Use password instead'));
      await tester.pumpAndSettle();
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Send code'), findsNothing);
    });
  });

  test('wait copy includes remaining seconds', () {
    expect(otpWaitCopy(47), contains('47s'));
    expect(otpWaitCopy(3600, rateLimited: true), contains('password login'));
  });

  test('user-facing messages cover every backend code', () {
    for (final code in OtpAuthCode.values) {
      expect(messageForOtpCode(code), isNotEmpty);
    }
  });
}
