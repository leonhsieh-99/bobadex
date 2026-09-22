import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

class AddCircleButton extends StatelessWidget {
  final double size;
  final VoidCallback? onPressed;

  const AddCircleButton({super.key, this.size = 48.0, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: context.boba.accent,
        shape: CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Center(
            child: Icon(
              Icons.add,
              color: context.boba.onAccent,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
