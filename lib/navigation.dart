// navigation.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> goRoot(String path) async {
  await WidgetsBinding.instance.endOfFrame;

  const tries = 30;
  for (var i = 0; i < tries; i++) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(path);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 16));
  }
}

bool rootCanPop() => rootNavigatorKey.currentState?.canPop() ?? false;

void rootPop() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null && ctx.mounted) GoRouter.of(ctx).pop();
}
