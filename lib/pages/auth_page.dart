import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/forgot_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import your helper files here...

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _isSigningUp = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final supabase = Supabase.instance.client;
    final userState = context.read<UserState>();
    final brandState = context.read<BrandState>();

    try {
      if (_isSigningUp) {
        if (_confirmPwController.text.trim() != password) {
          context.read<NotificationQueue>().queue('Passwords do not match', SnackType.error);
          return;
        }

        if (username.isEmpty || displayName.isEmpty) {
          context.read<NotificationQueue>().queue('Username and name are required', SnackType.error);
          return;
        }

        final usernameExists = await supabase.rpc('username_exists', params: {'input_username': username});
        if (usernameExists) {
          if (mounted) context.read<NotificationQueue>().queue('Username already taken', SnackType.error);
          return;
        }

        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'username': username,
            'display_name': displayName,
          },
        );

        if (response.session == null && response.user != null) {
          if (mounted) {
            context.read<NotificationQueue>().queue(
              'Check your email to confirm your account before logging in.',
              SnackType.success,
            );
          }
          return;
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: password);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('No session available after authentication');

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user found after auth');

      await userState.loadFromSupabase();
      await brandState.loadFromSupabase();
      if (!mounted) return;

    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid email')) {
        context.read<NotificationQueue>().queue('Please enter a valid email address.', SnackType.error);
      } else if (msg.contains('invalid login credentials') || msg.contains('invalid password')) {
        context.read<NotificationQueue>().queue('Incorrect email or password.', SnackType.error);
      } else {
        context.read<NotificationQueue>().queue(e.message, SnackType.error);
        debugPrint('Auth Error: $e');
      }
    } on PostgrestException catch (e) {
      context.read<NotificationQueue>().queue(e.message, SnackType.error);
    } catch (e) {
      context.read<NotificationQueue>().queue('An unexpected error occurred', SnackType.error);
      debugPrint('Postgres Error: $e');
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
                  validator: (val) {
                    if (val == null || val.length < 8) return 'Min 8 characters';
                    if (!RegExp(r'[A-Za-z]').hasMatch(val) || !RegExp(r'[0-9]').hasMatch(val)) {
                      return 'Use letters and numbers';
                    }
                    return null;
                  },
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
                    onPressed: _submit,
                    child: Text(_isSigningUp ? 'Create Account' : 'Log In'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSigningUp = !_isSigningUp),
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
