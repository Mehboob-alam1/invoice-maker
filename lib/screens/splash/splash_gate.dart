import 'package:flutter/material.dart';

import '../../ads/ad_flows.dart';
import '../../services/paywall_analytics.dart';
import '../../bootstrap/app_bootstrap.dart';
import '../../services/app_update_service.dart';
import '../../widgets/bottom_banner_host.dart';
import '../../widgets/splash_launch_view.dart';

/// Brand splash only while local data loads, then the first real screen.
class SplashShell extends StatefulWidget {
  const SplashShell({super.key, this.result});

  final AppBootstrapResult? result;

  @override
  State<SplashShell> createState() => _SplashShellState();
}

class _SplashShellState extends State<SplashShell> {
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(SplashShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || widget.result == null) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final result = widget.result;
    if (result == null || !mounted) return;
    setState(() => _done = true);
    // Let the home screen paint before paywall / update prompts.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (result.invoiceProvider.hasCompletedOnboarding) {
        await openPaywallIfFree(context, source: PaywallSource.launch);
      }
      if (!mounted) return;
      AppUpdateService.promptIfAvailable(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (_done && result != null) {
      final next = result.initialScreen;
      if (next is NoBottomBanner) return next;
      return BottomBannerHost(child: next);
    }
    return const SplashLaunchView();
  }
}
