import 'dart:async';

import 'package:bobadex/auth/otp_auth_client.dart';
import 'package:bobadex/auth/otp_auth_codes.dart';
import 'package:bobadex/auth/otp_auth_messages.dart';
import 'package:bobadex/auth/phone_e164.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/forgot_password_dialog.dart';
import 'package:bobadex/widgets/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _AuthView { otp, password, signup }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.otpClient});

  final OtpAuthClient? otpClient;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  late final OtpAuthClient _otpClient = widget.otpClient ?? OtpAuthClient();

  _AuthView _view = _AuthView.otp;
  bool _awaitingCode = false;
  String? _otpIdentifier;
  String? _cooldownIdentifier;
  DateTime? _resendAvailableAt;
  Timer? _resendTicker;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _resend = false;
  bool _loading = false;
  OtpAuthCode? _inlineError;

  String get _title => switch (_view) {
        _AuthView.signup => 'Sign Up',
        _AuthView.password => 'Log In',
        _AuthView.otp => _awaitingCode ? 'Enter code' : 'Log In',
      };

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
    _passwordController.dispose();
    _confirmPwController.dispose();
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
      _resend = false;
      _inlineError = null;
      if (view != _AuthView.otp) {
        _clearOtpFlow();
      }
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

  String? get _typedOtpIdentifier => emailToOtpIdentifier(_emailController.text);

  bool get _sendOnCooldown {
    final id = _typedOtpIdentifier ?? _otpIdentifier;
    return id != null &&
        id == _cooldownIdentifier &&
        _resendSecondsLeft > 0;
  }

  int get _resendSecondsLeft {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  void _startResendCooldown(String identifier, {int seconds = Constants.otpResendCooldownSeconds}) {
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
      await _otpClient.requestEmailLoginOtp(identifier);
      if (!mounted) return;
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
        _startResendCooldown(identifier, seconds: Constants.otpRateLimitCooldownSeconds);
        notify(otpWaitCopy(_resendSecondsLeft, rateLimited: true), SnackType.error);
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
      final tokens = await _otpClient.verifyEmailLoginOtp(email: identifier, code: code);
      _otpController.clear();
      await _otpClient.establishLoginSession(tokens);
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

  Future<void> _submitPasswordOrSignup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final userState = context.read<UserState>();

    try {
      if (_view == _AuthView.signup) {
        if (_confirmPwController.text.trim() != password) {
          notify('Passwords do not match', SnackType.error);
          return;
        }

        if (username.isEmpty || displayName.isEmpty) {
          notify('Username and name are required', SnackType.error);
          return;
        }

        final usernameExists = await supabase.rpc(
          'username_exists',
          params: {'input_username': username},
        );

        if (usernameExists == true) {
          notify('Username already taken', SnackType.error);
          return;
        }

        final emailTaken = await supabase.rpc(
          'email_exists',
          params: {'input_email': email.trim().toLowerCase()},
        ) as bool? ?? false;

        if (emailTaken) {
          notify('Email already in use', SnackType.error);
          return;
        }

        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'username': username,
            'display_name': displayName,
          },
          emailRedirectTo: 'bobadex://login',
        );

        if (response.user != null && response.session == null) {
          notify('Check your email to confirm your account.', SnackType.success);
          if (mounted) setState(() => _resend = true);
          return;
        }
      } else {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session == null) {
          throw Exception('Login failed: No session created');
        }
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await userState.loadCurrent();
      if (!mounted || context.read<UserState>().isLoaded) return;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid email')) {
        notify('Please enter a valid email address.', SnackType.error);
      } else if (msg.contains('invalid login credentials') || msg.contains('invalid password')) {
        notify('Incorrect email or password.', SnackType.error);
      } else {
        notify(e.message, SnackType.error);
      }
    } on PostgrestException catch (e) {
      notify(e.message, SnackType.error);
    } catch (_) {
      notify('An unexpected error occurred', SnackType.error);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _resendVerificationEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      notify('If that email can receive mail, you’ll get a confirmation link.', SnackType.info);
    } on AuthException catch (e) {
      notify(e.message, SnackType.error);
    } catch (_) {
      notify('Failed to resend verification email.', SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: _awaitingCode
            ? IconButton(
                tooltip: 'Edit email',
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _otpController.clear();
                          _awaitingCode = false;
                          _inlineError = null;
                        }),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_view == _AuthView.otp) ..._otpFields(),
                if (_view != _AuthView.otp) ..._passwordOrSignupFields(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || (_view == _AuthView.otp && !_awaitingCode && _sendOnCooldown))
                        ? null
                        : _primaryAction,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_primaryLabel),
                  ),
                ),
                if (_view == _AuthView.otp && _resendSecondsLeft > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        otpWaitCopy(
                          _resendSecondsLeft,
                          rateLimited: _inlineError == OtpAuthCode.rateLimited,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                if (_view == _AuthView.otp && _awaitingCode) ...[
                  TextButton(
                    onPressed: (_loading || _resendSecondsLeft > 0) ? null : () => _requestOtp(resend: true),
                    style: AppButtonStyles.textButton,
                    child: Text(
                      _resendSecondsLeft > 0
                          ? 'Resend code in ${formatOtpWaitDuration(_resendSecondsLeft)}'
                          : 'Resend code',
                    ),
                  ),
                ],
                if (_view == _AuthView.otp && !_awaitingCode)
                  TextButton(
                    onPressed: () => _setView(_AuthView.password),
                    style: AppButtonStyles.textButton,
                    child: const Text('Use password instead'),
                  ),
                if (_view == _AuthView.password)
                  TextButton(
                    onPressed: () => _setView(_AuthView.otp),
                    style: AppButtonStyles.textButton,
                    child: const Text('Use a code instead'),
                  ),
                if (_inlineError == OtpAuthCode.unknownUser)
                  TextButton(
                    onPressed: () => _setView(_AuthView.signup),
                    style: AppButtonStyles.textButton,
                    child: const Text('Create an account'),
                  ),
                TextButton(
                  onPressed: () => _setView(
                    _view == _AuthView.signup ? _AuthView.otp : _AuthView.signup,
                  ),
                  style: AppButtonStyles.textButton,
                  child: Text(
                    _view == _AuthView.signup
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up",
                  ),
                ),
                if (_inlineError != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        messageForOtpCode(_inlineError!),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _primaryLabel {
    if (_view == _AuthView.signup) {
      return _resend ? 'Resend Verification Email' : 'Create Account';
    }
    if (_view == _AuthView.password) return 'Log In';
    if (_awaitingCode) return 'Verify code';
    if (_sendOnCooldown) return 'Send code in ${formatOtpWaitDuration(_resendSecondsLeft)}';
    return 'Send code';
  }

  void _primaryAction() {
    if (_view == _AuthView.otp) {
      if (_awaitingCode) {
        _verifyOtp();
      } else {
        _requestOtp();
      }
      return;
    }
    if (_view == _AuthView.signup && _resend) {
      _resendVerificationEmail(_emailController.text.trim());
      return;
    }
    _submitPasswordOrSignup();
  }

  List<Widget> _otpFields() {
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
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        enabled: !_loading,
      ),
    ];
  }

  List<Widget> _passwordOrSignupFields() {
    final isSigningUp = _view == _AuthView.signup;
    return [
      if (isSigningUp)
        TextFormField(
          controller: _displayNameController,
          maxLength: Constants.maxNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', counterText: ''),
          validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
          autofillHints: const [AutofillHints.name],
        ),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Enter your email';
          if (!val.contains('@')) return 'Enter a valid email';
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      if (isSigningUp)
        TextFormField(
          maxLength: Constants.maxUsernameLength,
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Username', counterText: ''),
          validator: (val) => val == null || val.isEmpty ? 'Enter a username' : null,
        ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        validator: (value) {
          if (!isSigningUp) return null;
          final v = value?.trim() ?? '';
          if (v.isEmpty) return 'Please enter a password.';
          if (!Constants.passwordRegex.hasMatch(v)) {
            return 'Password must be 8+ chars with letters & numbers.';
          }
          return null;
        },
        obscureText: !_showPassword,
        autofillHints: const [AutofillHints.password],
      ),
      if (isSigningUp)
        TextFormField(
          controller: _confirmPwController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
          validator: (val) {
            if (val != _passwordController.text) return 'Passwords do not match';
            return null;
          },
          obscureText: !_showConfirmPassword,
        ),
      if (!isSigningUp)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: AppButtonStyles.textButton,
            onPressed: () {
              FocusScope.of(context).unfocus();
              showDialog(
                context: context,
                builder: (_) => const ForgotPasswordDialog(),
              );
            },
            child: const Text('Forgot password?'),
          ),
        ),
    ];
  }
}
