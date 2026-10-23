import 'dart:async';
import 'dart:io';

import 'package:bobadex/runtime/app_runtime_controls.dart';
import 'package:bobadex/runtime/gated_account_page.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppRuntimeGate extends StatefulWidget {
  const AppRuntimeGate({
    super.key,
    required this.child,
    this.load,
    this.platform,
    this.buildNumber,
    this.pollInterval = const Duration(seconds: 60),
  });

  final Widget child;
  final Future<AppRuntimeControls?> Function()? load;
  final AppPlatformKind? platform;
  final int? buildNumber;
  final Duration pollInterval;

  @override
  State<AppRuntimeGate> createState() => _AppRuntimeGateState();
}

class _AppRuntimeGateState extends State<AppRuntimeGate>
    with WidgetsBindingObserver {
  var _loaded = false;
  var _sawControls = false;
  var _epoch = 0;
  Future<AppRuntimeControls?>? _inFlight;
  RuntimeDecision _decision = const RuntimeDecision.allow();
  Timer? _poll;
  int? _buildNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildNumber = widget.buildNumber;
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  AppPlatformKind get _platform {
    if (widget.platform != null) return widget.platform!;
    if (Platform.isIOS) return AppPlatformKind.ios;
    if (Platform.isAndroid) return AppPlatformKind.android;
    return AppPlatformKind.other;
  }

  Future<void> _refresh() async {
    final epoch = ++_epoch;
    final pending = _inFlight ??= _readControls();
    AppRuntimeControls? controls;
    try {
      controls = await pending;
    } catch (_) {
      controls = null;
    } finally {
      if (identical(_inFlight, pending)) _inFlight = null;
    }
    if (!mounted || epoch != _epoch) return;

    if (controls == null) {
      if (!_sawControls) {
        setState(() {
          _loaded = true;
          _decision = const RuntimeDecision.allow();
        });
      }
      return;
    }

    final buildNumber = await _resolvedBuildNumber();
    if (!mounted || epoch != _epoch) return;
    setState(() {
      _loaded = true;
      _sawControls = true;
      _decision = decideRuntimeAccess(
        controls: controls,
        platform: _platform,
        buildNumber: buildNumber,
      );
    });
    _syncPoll();
  }

  Future<AppRuntimeControls?> _readControls() {
    final load = widget.load;
    if (load != null) return load();
    return loadAppRuntimeControls();
  }

  Future<int?> _resolvedBuildNumber() async {
    if (widget.buildNumber != null) return widget.buildNumber;
    if (_buildNumber != null) return _buildNumber;
    try {
      final info = await PackageInfo.fromPlatform();
      _buildNumber = int.tryParse(info.buildNumber);
    } catch (_) {
      _buildNumber = null;
    }
    return _buildNumber;
  }

  void _syncPoll() {
    if (_decision.blocked) {
      _poll ??= Timer.periodic(widget.pollInterval, (_) {
        unawaited(_refresh());
      });
      return;
    }
    _poll?.cancel();
    _poll = null;
  }

  bool get _signedIn {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_decision.blocked) return widget.child;
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => _RuntimeBlockPage(
          decision: _decision,
          signedIn: _signedIn,
          onRetry: _refresh,
        ),
      ),
    );
  }
}

class _RuntimeBlockPage extends StatefulWidget {
  const _RuntimeBlockPage({
    required this.decision,
    required this.signedIn,
    required this.onRetry,
  });

  final RuntimeDecision decision;
  final bool signedIn;
  final Future<void> Function() onRetry;

  @override
  State<_RuntimeBlockPage> createState() => _RuntimeBlockPageState();
}

class _RuntimeBlockPageState extends State<_RuntimeBlockPage> {
  StreamSubscription<AuthState>? _authSub;
  late bool _signedIn = widget.signedIn;

  @override
  void initState() {
    super.initState();
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        final signedIn = Supabase.instance.client.auth.currentSession != null;
        if (mounted && signedIn != _signedIn) {
          setState(() => _signedIn = signedIn);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decision = widget.decision;
    final signedIn = _signedIn;
    final tokens = context.boba;
    final title = decision.block == RuntimeBlock.maintenance
        ? 'Bobadex is unavailable'
        : 'Update required';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BobaSpace.x6),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                decision.block == RuntimeBlock.maintenance
                    ? Icons.hourglass_top_rounded
                    : Icons.system_update_rounded,
                size: 48,
                color: tokens.inkFaint,
              ),
              const SizedBox(height: BobaSpace.x4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: BobaSpace.x3),
              Text(
                decision.message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: tokens.inkMuted),
              ),
              if (decision.storeInstructions != null) ...[
                const SizedBox(height: BobaSpace.x3),
                Text(
                  decision.storeInstructions!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
                ),
              ],
              const SizedBox(height: BobaSpace.x5),
              if (decision.storeUrl != null)
                BobaButton(
                  label: decision.storeActionLabel ?? 'Update Bobadex',
                  expanded: true,
                  onPressed: () {
                    launchUrl(
                      decision.storeUrl!,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              if (decision.storeUrl != null)
                const SizedBox(height: BobaSpace.x3),
              BobaButton(
                label: 'Try again',
                expanded: true,
                variant: decision.storeUrl == null
                    ? BobaButtonVariant.primary
                    : BobaButtonVariant.secondary,
                onPressed: () => widget.onRetry(),
              ),
              const Spacer(),
              if (signedIn)
                BobaButton(
                  label: 'Account and help',
                  variant: BobaButtonVariant.tertiary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GatedAccountPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
