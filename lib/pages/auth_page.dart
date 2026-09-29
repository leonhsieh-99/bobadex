import 'dart:async';

import 'package:bobadex/auth/email_account_auth.dart';
import 'package:bobadex/auth/otp_auth_client.dart';
import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:bobadex/auth/otp_auth_messages.dart';
import 'package:bobadex/auth/phone_e164.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_sheet.dart';
import 'package:bobadex/ui/components/dex_backdrop.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum _AuthView { login, signup }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.otpClient, this.emailAuth});

  final OtpAuthClient? otpClient;
  final EmailAccountAuth? emailAuth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  late final OtpAuthClient _otpClient = widget.otpClient ?? OtpAuthClient();
  late final EmailAccountAuth _emailAuth =
      widget.emailAuth ?? EmailAccountAuth();

  _AuthView _view = _AuthView.login;
  bool _awaitingCode = false;
  String? _otpIdentifier;
  String? _cooldownIdentifier;
  DateTime? _resendAvailableAt;
  Timer? _resendTicker;
  bool _loading = false;
  OtpAuthCode? _inlineError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTicker?.cancel();
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep identifier + code-entry step; do not treat resume as signed in.
  }

  void _setView(_AuthView view) {
    setState(() {
      _view = view;
      _inlineError = null;
      _clearOtpFlow();
    });
  }

  void _clearOtpFlow() {
    _otpController.clear();
    _awaitingCode = false;
    _otpIdentifier = null;
    _cooldownIdentifier = null;
    _resendAvailableAt = null;
    _resendTicker?.cancel();
  }

  String? get _typedOtpIdentifier =>
      emailToOtpIdentifier(_emailController.text);

  bool get _sendOnCooldown {
    final id = _typedOtpIdentifier ?? _otpIdentifier;
    return id != null && id == _cooldownIdentifier && _resendSecondsLeft > 0;
  }

  int get _resendSecondsLeft {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  void _startResendCooldown(
    String identifier, {
    int seconds = Constants.otpResendCooldownSeconds,
  }) {
    _cooldownIdentifier = identifier;
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
    _resendTicker?.cancel();
    _resendTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resendSecondsLeft == 0) {
        _resendTicker?.cancel();
      }
      setState(() {});
    });
    setState(() {});
  }

  Future<void> _requestOtp({bool resend = false}) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _inlineError = null);

    if (_view == _AuthView.signup && !resend) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }

    final identifier = emailToOtpIdentifier(_emailController.text);
    if (identifier == null) {
      setState(() => _inlineError = OtpAuthCode.invalidIdentifier);
      notify(messageForOtpCode(OtpAuthCode.invalidIdentifier), SnackType.error);
      return;
    }

    if (!resend && _otpIdentifier != identifier) {
      _otpController.clear();
    }

    if (identifier == _cooldownIdentifier && _resendSecondsLeft > 0) {
      notify(otpWaitCopy(_resendSecondsLeft), SnackType.info);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = _view == _AuthView.signup
          ? await _emailAuth.requestSignup(
              email: identifier,
              username: _usernameController.text.trim(),
              displayName: _displayNameController.text.trim(),
            )
          : await _otpClient.requestEmailLoginOtp(identifier);
      if (!mounted) return;
      if (result == OtpAuthCode.success) return;
      setState(() {
        _otpIdentifier = identifier;
        _awaitingCode = true;
        _inlineError = null;
      });
      _startResendCooldown(identifier);
      notify(
        '${messageForOtpCode(OtpAuthCode.otpSent)} ${otpWaitCopy(Constants.otpResendCooldownSeconds)}',
        SnackType.info,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocus.requestFocus();
      });
    } on OtpAuthException catch (e) {
      if (!mounted) return;
      setState(() => _inlineError = e.code);
      if (e.code == OtpAuthCode.rateLimited) {
        _startResendCooldown(identifier);
        notify(
          otpWaitCopy(_resendSecondsLeft, rateLimited: true),
          SnackType.error,
        );
      } else {
        notify(messageForOtpCode(e.code), SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading) return;
    final identifier = _otpIdentifier;
    if (identifier == null) return;
    final code = _otpController.text.trim();
    if (!isOtpCode(code)) {
      setState(() => _inlineError = OtpAuthCode.invalidOtp);
      notify(messageForOtpCode(OtpAuthCode.invalidOtp), SnackType.error);
      return;
    }

    setState(() {
      _loading = true;
      _inlineError = null;
    });
    try {
      if (_view == _AuthView.signup) {
        await _emailAuth.verifySignup(email: identifier, code: code);
        _otpController.clear();
      } else {
        final tokens = await _otpClient.verifyEmailLoginOtp(
          email: identifier,
          code: code,
        );
        _otpController.clear();
        await _otpClient.establishLoginSession(tokens);
      }
    } on OtpAuthException catch (e) {
      if (!mounted) return;
      setState(() => _inlineError = e.code);
      notify(messageForOtpCode(e.code), SnackType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineError = OtpAuthCode.authError);
      notify(messageForOtpCode(OtpAuthCode.authError), SnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _sheetTitle => switch (_view) {
    _AuthView.signup => _awaitingCode ? 'Check your inbox' : 'Create account',
    _AuthView.login => _awaitingCode ? 'Check your inbox' : 'Log in',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DexBackdrop(),
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BobaSpace.x6,
                          vertical: BobaSpace.x3,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'lib/assets/logo.svg',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: BobaSpace.x3),
                            Text(
                              'Your boba collection, one cup at a time.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: tokens.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: BobaSheet(
              expand: true,
              padding: const EdgeInsets.fromLTRB(
                BobaSpace.x6,
                BobaSpace.x5,
                BobaSpace.x6,
                BobaSpace.x4,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (_awaitingCode)
                                IconButton(
                                  tooltip: 'Edit email',
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() {
                                          _otpController.clear();
                                          _awaitingCode = false;
                                          _inlineError = null;
                                        }),
                                ),
                              Expanded(
                                child: Text(
                                  _sheetTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BobaSpace.x4),
                          ..._fields(),
                          const SizedBox(height: BobaSpace.x5),
                          BobaButton(
                            label: _primaryLabel,
                            expanded: true,
                            loading: _loading,
                            onPressed:
                                (_loading ||
                                    (!_awaitingCode && _sendOnCooldown))
                                ? null
                                : _primaryAction,
                          ),
                          if (_resendSecondsLeft > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  otpWaitCopy(
                                    _resendSecondsLeft,
                                    rateLimited:
                                        _inlineError == OtpAuthCode.rateLimited,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: tokens.inkMuted),
                                ),
                              ),
                            ),
                          if (_awaitingCode)
                            BobaButton(
                              variant: BobaButtonVariant.tertiary,
                              label: _resendSecondsLeft > 0
                                  ? 'Resend code in ${formatOtpWaitDuration(_resendSecondsLeft)}'
                                  : 'Resend code',
                              onPressed: (_loading || _resendSecondsLeft > 0)
                                  ? null
                                  : () => _requestOtp(resend: true),
                            ),
                          if (_inlineError == OtpAuthCode.unknownUser)
                            BobaButton(
                              variant: BobaButtonVariant.tertiary,
                              label: 'Create an account',
                              onPressed: () => _setView(_AuthView.signup),
                            ),
                          if (_inlineError == OtpAuthCode.emailAlreadyInUse &&
                              _view == _AuthView.signup)
                            BobaButton(
                              variant: BobaButtonVariant.tertiary,
                              label: 'Log in instead',
                              onPressed: () => _setView(_AuthView.login),
                            ),
                          const SizedBox(height: BobaSpace.x2),
                          BobaButton(
                            variant: BobaButtonVariant.tertiary,
                            label: _view == _AuthView.signup
                                ? 'Already have an account? Log in'
                                : "Don't have an account? Sign up",
                            onPressed: () => _setView(
                              _view == _AuthView.signup
                                  ? _AuthView.login
                                  : _AuthView.signup,
                            ),
                          ),
                          if (_inlineError != null)
                            Semantics(
                              liveRegion: true,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  messageForOtpCode(_inlineError!),
                                  style: TextStyle(color: tokens.danger),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _primaryLabel {
    if (_awaitingCode) return 'Verify code';
    if (_sendOnCooldown)
      return 'Send code in ${formatOtpWaitDuration(_resendSecondsLeft)}';
    return 'Send code';
  }

  void _primaryAction() {
    if (_awaitingCode) {
      _verifyOtp();
    } else {
      _requestOtp();
    }
  }

  List<Widget> _fields() {
    if (_awaitingCode) {
      return [
        Text('Enter the code sent to $_otpIdentifier'),
        const SizedBox(height: 12),
        OtpCodeField(
          controller: _otpController,
          focusNode: _otpFocus,
          enabled: !_loading,
          onSubmitted: (_) => _verifyOtp(),
        ),
      ];
    }

    return [
      if (_view == _AuthView.signup) ...[
        TextFormField(
          controller: _displayNameController,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', counterText: ''),
          validator: Validators.validateDisplayName,
          autofillHints: const [AutofillHints.name],
          enabled: !_loading,
        ),
        TextFormField(
          maxLength: 15,
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            counterText: '',
          ),
          validator: Validators.validateUsername,
          enabled: !_loading,
        ),
      ],
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        enabled: !_loading,
        validator: _view == _AuthView.signup ? Validators.validateEmail : null,
      ),
    ];
  }
}
