import 'package:bobadex/config/constants.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddCircleButton extends StatelessWidget {
  final double size;
  final VoidCallback? onPressed;

  const AddCircleButton({
    super.key,
    this.size = 48.0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserState>().current;
    final themeColor = Constants.getThemeColor(user.themeSlug);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: themeColor.shade500,
        shape: CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
