import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

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

    try {
      print('📦 Starting auth process...');
      
      if (_isSigningUp) {
        print('📦 Signing up...');
        if (username.isEmpty || displayName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username and name are required')),
          );
          return;
        }
        final taken = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
        if (taken != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken'))
          );
          return;
        }
        final response = await supabase.auth.signUp(email: email, password: password);
        print('📦 Sign up response: ${response.session}');
      } else {
        print('📦 Signing in...');
        final response = await supabase.auth.signInWithPassword(email: email, password: password);
        print('📦 Sign in response: ${response.session}');
      }

      // Wait a bit for the session to be properly set
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = supabase.auth.currentSession;
      print('📦 Current session after auth: $session');
      
      if (session == null) {
        throw Exception('No session available after authentication');
      }

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user found after auth');
      final userId = user.id;
      print('📦 User ID: $userId');

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

      if (!mounted) return;
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => HomePage(session: session)),
      );
    } on AuthException catch(e) {
      print('📦 Auth error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message))
      );
    } catch (e) {
      print('📦 Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred'))
      );
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
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              autofocus: true,
            ),
            if (_isSigningUp)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
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