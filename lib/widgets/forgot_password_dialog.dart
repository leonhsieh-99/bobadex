import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendReset() async {
    setState(() { _isLoading = true; _message = null; });
    final email = _emailController.text.trim();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() {
        _message = "Check your email for a password reset link!";
      });
    } catch (e) {
      setState(() {
        _message = "Error: ${e.toString()}";
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter your email and we’ll send you a password reset link."),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_message != null) ...[
            SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(color: _message!.startsWith("Error") ? Colors.red : Colors.green),
            ),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendReset,
          child: _isLoading ? CircularProgressIndicator() : Text('Send Link'),
        ),
      ],
    );
  }
}
