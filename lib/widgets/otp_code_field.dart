import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  const OtpCodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
    this.errorText,
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
        errorText: widget.errorText,
      ),
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}
