import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/forgot_password_dialog.dart';
import 'package:flutter/material.dart';
// import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import your helper files here...

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _isSigningUp = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _resend = false;
  bool _loading = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final userState = context.read<UserState>();

    try {
      if (_isSigningUp) {
        // Validate password match
        if (_confirmPwController.text.trim() != password) {
          notify('Passwords do not match', SnackType.error);
          return;
        }

        if (username.isEmpty || displayName.isEmpty) {
          notify('Username and name are required', SnackType.error);
          return;
        }

        // Check username availability
        final usernameExists = await supabase.rpc(
          'username_exists',
          params: {'input_username': username},
        );

        if (usernameExists == true) {
          notify('Username already taken', SnackType.error);
          return;
        }

        // First-time signup: pass metadata for the supabase trigger to make rows
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
        // Login
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session == null) {
          throw Exception('Login failed: No session created');
        }
      }

      // Confirm current user is available
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Load user state
      await userState.loadFromSupabase();
      if (!mounted || context.read<UserState>().isLoaded) return;

    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid email')) {
        notify('Please enter a valid email address.', SnackType.error);
      } else if (msg.contains('invalid login credentials') || msg.contains('invalid password')) {
        notify('Incorrect email or password.', SnackType.error);
      } else {
        notify(e.message, SnackType.error);
        debugPrint('Auth Error: $e');
      }
    } on PostgrestException catch (e) {
      notify(e.message, SnackType.error);
    } catch (e) {
      notify('An unexpected error occurred', SnackType.error);
      debugPrint('Postgres Error: $e');
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _resendVerificationEmail(String email) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      notify('Verification email resent. Check your inbox.', SnackType.success);
    } on AuthException catch (e) {
      notify(e.message, SnackType.error);
      debugPrint('Auth resend error: $e');
    } catch (e) {
      notify('Failed to resend verification email.', SnackType.error);
      debugPrint('Unexpected resend error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPwController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSigningUp ? 'Sign Up' : 'Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                if (_isSigningUp)
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
                if (_isSigningUp)
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
                  validator: (value) => 
                    value != null && Constants.passwordRegex.hasMatch(value)
                      ? null
                      : 'Password must be at least 8 characters and include both letters and numbers.',
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.password],
                ),
                if (_isSigningUp)
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: AppButtonStyles.textButton,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ForgotPasswordDialog(),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade200),
                    onPressed: () {
                      if (_loading) {
                        return;
                      } else if (_isSigningUp && _resend) {
                        _resendVerificationEmail(_emailController.text.trim());
                      } else {
                        _submit();
                      }
                    },
                  child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : Text(_isSigningUp
                        ? (_resend ? 'Resend Verification Email' : 'Create Account')
                        : 'Log In'
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() { 
                    _isSigningUp = !_isSigningUp;
                    _resend = false;
                  }),
                  style: AppButtonStyles.textButton,
                  child: Text(
                    _isSigningUp
                      ? 'Already have an account? Log in'
                      : 'Don\'t have an account? Sign up',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
