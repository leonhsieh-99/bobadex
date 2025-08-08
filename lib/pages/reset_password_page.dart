import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/pages/auth_page.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  final Function onDone;

  const ResetPasswordPage({super.key, required this.onDone});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  
  Future<void> _resetPassword() async {
    final newPassword = _passwordController.text.trim();
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('Password reset');
      if (mounted) {
        context.read<NotificationQueue>().queue('Password successfully reset', SnackType.success);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthPage()));
        widget.onDone();
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
      if (mounted) context.read<NotificationQueue>().queue('Error resetting password, please try again.', SnackType.error);
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        widget.onDone();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthPage()));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Password Reset'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AuthPage())
              )
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
                      widget.onDone(); // This resets the flag in parent
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Confirm')
                )
              ],
            ),
          )
        ),
      )
    );
  }
}