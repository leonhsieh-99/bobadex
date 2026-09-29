import 'package:flutter/material.dart';

class BranchNavNotifier extends NavigatorObserver with ChangeNotifier {
  bool canPop = false;
  bool _notifyScheduled = false;

  void _sync() {
    final next = navigator?.canPop() ?? false;
    if (next == canPop) return;
    canPop = next;
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _sync();
}
