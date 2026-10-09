import 'dart:async';

import 'package:bobadex/config/constants.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

enum SnackType { info, success, error, achievement }

class TopSnackBar extends StatefulWidget {
  final String message;
  final SnackType type;
  final Duration duration;
  final VoidCallback? onDismissed;

  const TopSnackBar({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(milliseconds: Constants.snackBarDuration),
    this.onDismissed,
  });

  @override
  State<TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _hideTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: BobaMotion.normal);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _hideTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _hideTimer?.cancel();
    try {
      await _controller.reverse();
    } catch (_) {}
    if (!mounted) return;
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final achievement = widget.type == SnackType.achievement;
    final background = achievement ? tokens.accentSoft : tokens.surface;
    final foreground = achievement ? tokens.accentInk : tokens.ink;
    final iconColor = switch (widget.type) {
      SnackType.success => tokens.success,
      SnackType.error => tokens.danger,
      SnackType.achievement => tokens.accentInk,
      SnackType.info => tokens.accent,
    };
    final icon = switch (widget.type) {
      SnackType.success => Icons.check_circle_rounded,
      SnackType.error => Icons.error_outline_rounded,
      SnackType.achievement => Icons.emoji_events_rounded,
      SnackType.info => Icons.info_outline_rounded,
    };

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: background,
              elevation: 0,
              borderRadius: BorderRadius.circular(BobaRadius.md),
              child: InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(BobaRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BobaRadius.md),
                    border: Border.all(
                      color: achievement ? tokens.accentInk : tokens.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
