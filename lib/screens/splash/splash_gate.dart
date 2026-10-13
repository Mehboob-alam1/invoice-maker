import 'package:flutter/material.dart';

import '../../ads/ad_placement.dart';
import '../../ads/ad_service.dart';
import '../../ads/ad_flows.dart';
import '../../bootstrap/app_bootstrap.dart';
import '../../widgets/native_ad_host.dart';
import '../../widgets/placement_banner_ad.dart';
import '../../widgets/splash_launch_view.dart';

/// One splash for the whole startup. Stays on screen through bootstrap, the
/// app-open ad, and the returning-user paywall, then opens the next screen.
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
    final provider = result.invoiceProvider;
    await AdService.instance.showAppOpenOnDemand(
      tier: provider.subscriptionTier,
      placement: AdPlacement.appOpenSplash,
      ignoreInterval: true,
    );
    if (!mounted) return;
    if (provider.hasCompletedOnboarding) {
      await openPaywallIfFree(context);
    }
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (_done && result != null) {
      return NativeAdHost(
        adScopeKey: 'start',
        child: result.initialScreen,
      );
    }
    return ColoredBox(
      color: SplashLaunchView.backgroundColor,
      child: Column(
        children: [
          const Expanded(child: SplashLaunchView()),
          if (result != null) const PlacementBannerAd(placement: AdPlacement.bannerSplash),
        ],
      ),
    );
  }
}
