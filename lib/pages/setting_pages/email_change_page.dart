import 'dart:async';

import 'package:bobadex/auth/email_account_auth.dart';
import 'package:bobadex/auth/otp_auth_client.dart';
import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:bobadex/auth/otp_auth_messages.dart';
import 'package:bobadex/auth/phone_e164.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/widgets/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _EmailChangeStep { currentEmail, currentCode, newEmail, newCode }

class EmailChangePage extends StatefulWidget {
  const EmailChangePage({
    super.key,
    this.emailAuth,
    this.otpClient,
    this.accountEmail,
  });

  final EmailAccountAuth? emailAuth;
  final OtpAuthClient? otpClient;
  final String? Function()? accountEmail;

  @override
  State<EmailChangePage> createState() => _EmailChangePageState();
}

class _EmailChangePageState extends State<EmailChangePage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  late final EmailAccountAuth _emailAuth =
      widget.emailAuth ?? EmailAccountAuth();
  late final OtpAuthClient _otpClient = widget.otpClient ?? OtpAuthClient();

  _EmailChangeStep _step = _EmailChangeStep.currentEmail;
  bool _loading = false;
  bool _currentVerified = false;
  String? _currentPending;
  String? _newPending;
  String? _cooldownEmail;
  DateTime? _resendAvailableAt;
  Timer? _resendTicker;
  OtpAuthCode? _inlineError;

  String? get _accountEmail => emailToOtpIdentifier(
    widget.accountEmail?.call() ??
        Supabase.instance.client.auth.currentUser?.email ??
        '',
  );

  bool get _onCodeStep =>
      _step == _EmailChangeStep.currentCode ||
      _step == _EmailChangeStep.newCode;

  int get _resendSecondsLeft {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  @override
  void dispose() {
    _resendTicker?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _clearCooldown() {
    _cooldownEmail = null;
    _resendAvailableAt = null;
    _resendTicker?.cancel();
  }

  void _startResendCooldown(
    String email, {
    int seconds = Constants.otpResendCooldownSeconds,
  }) {
    _cooldownEmail = email;
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
    _resendTicker?.cancel();
    _resendTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resendSecondsLeft == 0) _resendTicker?.cancel();
      setState(() {});
    });
    setState(() {});
  }

  void _goBackInFlow() {
    setState(() {
      _otpController.clear();
      _inlineError = null;
      switch (_step) {
        case _EmailChangeStep.currentCode:
          _step = _EmailChangeStep.currentEmail;
          _emailController.text = _currentPending ?? '';
        case _EmailChangeStep.newEmail:
          _step = _EmailChangeStep.currentEmail;
          _emailController.text = _currentPending ?? '';
          _newPending = null;
          _currentVerified = false;
          _clearCooldown();
        case _EmailChangeStep.newCode:
          _step = _EmailChangeStep.newEmail;
          _emailController.text = _newPending ?? '';
        case _EmailChangeStep.currentEmail:
          break;
      }
    });
  }

  Future<void> _requestCode({bool resend = false}) async {
    if (_loading) return;
    final email = emailToOtpIdentifier(_emailController.text);
    if (email == null) {
      setState(() => _inlineError = OtpAuthCode.invalidIdentifier);
      notify(messageForOtpCode(OtpAuthCode.invalidIdentifier), SnackType.error);
      return;
    }
    if (email == _cooldownEmail && _resendSecondsLeft > 0) {
      notify(otpWaitCopy(_resendSecondsLeft), SnackType.info);
      return;
    }

    final provingCurrent =
        _step == _EmailChangeStep.currentEmail ||
        _step == _EmailChangeStep.currentCode;
    if (provingCurrent) {
      final account = _accountEmail;
      if (account == null) {
        setState(() => _inlineError = OtpAuthCode.authRequired);
        notify(messageForOtpCode(OtpAuthCode.authRequired), SnackType.error);
        return;
      }
      if (email != account) {
        setState(() => _inlineError = OtpAuthCode.currentEmailMismatch);
        notify(
          messageForOtpCode(OtpAuthCode.currentEmailMismatch),
          SnackType.error,
        );
        return;
      }
    } else if (!_currentVerified) {
      setState(() => _inlineError = OtpAuthCode.authRequired);
      notify(messageForOtpCode(OtpAuthCode.authRequired), SnackType.error);
      return;
    }

    setState(() {
      _loading = true;
      _inlineError = null;
    });
    try {
      if (provingCurrent) {
        await _otpClient.requestEmailLoginOtp(email);
        if (!mounted) return;
        setState(() {
          _currentPending = email;
          _step = _EmailChangeStep.currentCode;
        });
      } else {
        await _emailAuth.requestEmailChange(email);
        if (!mounted) return;
        setState(() {
          _newPending = email;
          _step = _EmailChangeStep.newCode;
        });
      }
      _startResendCooldown(email);
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
        _startResendCooldown(email);
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

  Future<void> _verify() async {
    if (_loading) return;
    final email = _step == _EmailChangeStep.currentCode
        ? _currentPending
        : _newPending;
    if (email == null) return;
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
      if (_step == _EmailChangeStep.currentCode) {
        await _otpClient.verifyEmailLoginOtp(email: email, code: code);
        if (!mounted) return;
        _otpController.clear();
        _emailController.clear();
        _clearCooldown();
        setState(() {
          _currentVerified = true;
          _step = _EmailChangeStep.newEmail;
          _inlineError = null;
        });
        notify(
          'Current email confirmed. Enter your new email.',
          SnackType.info,
        );
      } else {
        await _emailAuth.verifyEmailChange(email: email, code: code);
        if (!mounted) return;
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final sendDisabled =
        _loading ||
        (!_onCodeStep &&
            emailToOtpIdentifier(_emailController.text) == _cooldownEmail &&
            _resendSecondsLeft > 0);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == _EmailChangeStep.newEmail ||
                  _step == _EmailChangeStep.newCode
              ? 'New email'
              : 'Confirm email',
        ),
        leading: _step == _EmailChangeStep.currentEmail
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading ? null : _goBackInFlow,
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_prompt),
          const SizedBox(height: 16),
          if (_onCodeStep)
            OtpCodeField(
              controller: _otpController,
              focusNode: _otpFocus,
              enabled: !_loading,
              onSubmitted: (_) => _verify(),
            )
          else
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: _step == _EmailChangeStep.newEmail
                    ? 'New email'
                    : 'Current email',
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: sendDisabled
                ? null
                : (_onCodeStep ? _verify : () => _requestCode()),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_primaryLabel),
          ),
          if (_onCodeStep)
            TextButton(
              onPressed: (_loading || _resendSecondsLeft > 0)
                  ? null
                  : () => _requestCode(resend: true),
              child: Text(
                _resendSecondsLeft > 0
                    ? 'Resend code in ${formatOtpWaitDuration(_resendSecondsLeft)}'
                    : 'Resend code',
              ),
            ),
          if (_resendSecondsLeft > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                otpWaitCopy(
                  _resendSecondsLeft,
                  rateLimited: _inlineError == OtpAuthCode.rateLimited,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          if (_inlineError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                messageForOtpCode(_inlineError!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String get _prompt => switch (_step) {
    _EmailChangeStep.currentEmail =>
      'Enter the email on this account. We will send a code there first.',
    _EmailChangeStep.currentCode => 'Enter the code sent to $_currentPending',
    _EmailChangeStep.newEmail =>
      'Enter the new email. We will send a second code there.',
    _EmailChangeStep.newCode => 'Enter the code sent to $_newPending',
  };

  String get _primaryLabel {
    if (_onCodeStep) return 'Verify code';
    if (_resendSecondsLeft > 0 &&
        emailToOtpIdentifier(_emailController.text) == _cooldownEmail) {
      return 'Send code in ${formatOtpWaitDuration(_resendSecondsLeft)}';
    }
    return 'Send code';
  }
}
