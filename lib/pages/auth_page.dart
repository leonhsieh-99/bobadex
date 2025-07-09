import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage ({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSigningUp = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final supabase = Supabase.instance.client;

    final userState = context.read<UserState>();
    final brandState = context.read<BrandState>();

    try {
      debugPrint('📦 Starting auth process...');
      
      if (_isSigningUp) {
        debugPrint('📦 Signing up...');
        if (username.isEmpty || displayName.isEmpty) {
        showAppSnackBar(context, 'Username and name are required', type: SnackType.error);
          return;
        }

        final usernameExists = await supabase.rpc('username_exists', params: {'input_username': username});
        if (usernameExists) {
        showAppSnackBar(context, 'Username already taken', type: SnackType.error);
          return;
        }

        final response = await supabase.auth.signUp(email: email, password: password);
        debugPrint('📦 Sign up response: ${response.session}');
      } else {
        debugPrint('📦 Signing in...');
        final response = await supabase.auth.signInWithPassword(email: email, password: password);
        debugPrint('📦 Sign in response: ${response.session}');
      }

      // Wait a bit for the session to be properly set
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = supabase.auth.currentSession;
      debugPrint('📦 Current session after auth: $session');
      
      if (session == null) {
        throw Exception('No session available after authentication');
      }

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user found after auth');
      final userId = user.id;
      debugPrint('📦 User ID: $userId');

      if (_isSigningUp && username.isNotEmpty) {
        final existing = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

        if (existing == null) {
          await supabase.from('users').insert({
            'id': userId,
            'username': username,
            'display_name': displayName,
          });
          await supabase.from('user_settings').insert({
            'user_id': userId,
            'theme_slug': 'grey',
            'grid_columns': 3,
          });
        }
      }

      await userState.loadFromSupabase();
      await brandState.loadFromSupabase();

      if (!mounted) return; // back to app initializer
    } on AuthException catch(e) {
      if (e.message.contains('User already registered')) {
        showAppSnackBar(context, 'Email already taken', type: SnackType.error);
      } else {
        debugPrint('📦 Auth error: ${e.message}');
        showAppSnackBar(context, 'Error ${e.message}', type: SnackType.error);
      }
    } catch (e) {
      debugPrint('email: $email');
      debugPrint('📦 Unexpected error: $e');
        showAppSnackBar(context, 'An unexpected error occurred', type: SnackType.error);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSigningUp ? 'Sign Up' : 'Log in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isSigningUp)
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: Validators.validateDisplayName,
              ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              autofocus: true,
              validator: Validators.validateEmail,
            ),
            if (_isSigningUp)
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: Validators.validateUsername,
              ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isSigningUp ? 'Create account' : 'Log in')
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSigningUp = !_isSigningUp;
                });
              },
              child: Text(_isSigningUp
              ? 'Already have an account ? Log in'
              : 'Don\'t have an account ? Sign up'
              )
            ),
          ]
        ),
      ),
    );
  }
}