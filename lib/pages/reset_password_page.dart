import 'package:bobadex/config/constants.dart';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  
  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final newPassword = _passwordController.text.trim();
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('Password reset');
      notify('Password successfully reset', SnackType.success);
      await goRoot('/auth');
    } catch (e) {
      debugPrint('Error resetting password: $e');
      notify('Error resetting password, please try again.', SnackType.error);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => goRoot('/auth')
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword)
                  )
                ),
                obscureText: !_showPassword,
                validator: (value) => 
                  value != null && Constants.passwordRegex.hasMatch(value)
                    ? null
                    : 'Password must be at least 8 characters and include both letters and numbers.'
              ),
              TextFormField(
                controller: _confirmationController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword)
                  )
                ),
                obscureText: !_showPassword,
                validator: (value) =>
                  value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _resetPassword();
                    // Navigation is handled by auth state listener
                  }
                },
                child: Text('Confirm')
              )
            ],
          ),
        )
      ),
    );
  }
}