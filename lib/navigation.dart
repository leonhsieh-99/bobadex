// navigation.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _dismissModalsIfAny() async {
  final nav = rootNavigatorKey.currentState;
  if (nav == null) return;
  for (var i = 0; i < 5; i++) {
    if (!nav.canPop()) break;
    nav.pop(); // dismiss top-most modal/page
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> goRoot(String path) async {
  // endOfFrame never completes if the raster thread stalls after the splash
  // has already painted. Waiting on it is what kept the splash up overnight.
  try {
    await WidgetsBinding.instance.endOfFrame.timeout(
      const Duration(milliseconds: 300),
    );
  } on TimeoutException {
    debugPrint('goRoot($path) skipped a stalled frame');
  }

  const tries = 30;
  for (var i = 0; i < tries; i++) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await _dismissModalsIfAny();
      final next = rootNavigatorKey.currentContext;
      if (next != null && next.mounted) {
        GoRouter.of(next).go(path);
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 16));
  }
  debugPrint('goRoot($path) gave up; navigator was not ready');
}

bool rootCanPop() => rootNavigatorKey.currentState?.canPop() ?? false;

void rootPop() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null && ctx.mounted) GoRouter.of(ctx).pop();
}
