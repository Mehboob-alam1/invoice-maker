import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_service.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';

/// Shows app-open ads when returning to foreground (tier-aware).
class AppOpenLifecycle extends StatefulWidget {
  const AppOpenLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<AppOpenLifecycle> createState() => _AppOpenLifecycleState();
}

class _AppOpenLifecycleState extends State<AppOpenLifecycle> with WidgetsBindingObserver {
  bool _coldStartHandled = false;
  SubscriptionTier _tier = SubscriptionTier.free;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _coldStartHandled) {
      AdService.instance.showAppOpenIfAvailable(tier: _tier);
    }
  }

  @override
  Widget build(BuildContext context) {
    _tier = context.watch<InvoiceProvider>().subscriptionTier;
    if (!_coldStartHandled) {
      _coldStartHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdService.instance.showColdStartAppOpen(tier: _tier);
      });
    }
    return widget.child;
  }
}
