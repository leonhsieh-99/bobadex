import 'package:bobadex/helpers/branch_nav.dart';
import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.branchNotifiers,
  });

  final StatefulNavigationShell navigationShell;
  final List<BranchNavNotifier> branchNotifiers;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _collapsed = false;

  bool get _forceHide {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return keyboardOpen || _currentBranchCanPop();
  }

  bool _currentBranchCanPop() {
    final index = widget.navigationShell.currentIndex;
    if (index < 0 || index >= widget.branchNotifiers.length) return false;
    return widget.branchNotifiers[index].canPop;
  }

  void _onTabSelected(int index) {
    setState(() => _collapsed = false);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (_forceHide) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 8 && !_collapsed) {
        setState(() => _collapsed = true);
      } else if (delta < -8 && _collapsed) {
        setState(() => _collapsed = false);
      }
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
        if (_collapsed) setState(() => _collapsed = false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: BobaNavBar.bottomOffset(context),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BobaSpace.x4,
                  ),
                  child: ListenableBuilder(
                    listenable: Listenable.merge(widget.branchNotifiers),
                    builder: (context, _) {
                      final friendsBadge = context.select<FriendState, int>(
                        (s) => s.incomingRequests.length,
                      );
                      final visible = !_forceHide && !_collapsed;
                      return IgnorePointer(
                        ignoring: !visible,
                        child: AnimatedSlide(
                          duration: BobaMotion.normal,
                          curve: Curves.easeOutCubic,
                          offset: visible ? Offset.zero : const Offset(0, 1.4),
                          child: AnimatedOpacity(
                            duration: BobaMotion.fast,
                            opacity: visible ? 1 : 0,
                            child: BobaNavBar(
                              selectedIndex:
                                  widget.navigationShell.currentIndex,
                              friendsBadgeCount: friendsBadge,
                              onDestinationSelected: _onTabSelected,
                              onAddPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .push(
                                      MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (_) =>
                                            const AddShopSearchPage(),
                                      ),
                                    );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
