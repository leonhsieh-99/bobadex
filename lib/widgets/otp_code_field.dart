import 'package:bobadex/auth/otp_auth_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? helperText;

  const OtpCodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
    this.errorText,
    this.helperText = otpInboxHint,
  });

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        labelText: 'Verification code',
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorText: widget.errorText,
      ),
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}
