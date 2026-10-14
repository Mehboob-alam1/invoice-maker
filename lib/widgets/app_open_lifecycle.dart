import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
import '../ads/ad_manager.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import '../services/subscription_service.dart';

/// Shows app-open ads when returning to foreground (tier-aware).
class AppOpenLifecycle extends StatefulWidget {
  const AppOpenLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<AppOpenLifecycle> createState() => _AppOpenLifecycleState();
}

class _AppOpenLifecycleState extends State<AppOpenLifecycle> with WidgetsBindingObserver {
  SubscriptionTier _tier = SubscriptionTier.free;
  bool _hasPaused = false;

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
    if (state == AppLifecycleState.paused) {
      _hasPaused = true;
      AdManager.instance.notePaused();
    }
    if (state == AppLifecycleState.resumed && _hasPaused) {
      unawaited(() async {
        await AdRemoteConfig.instance.refresh();
        if (mounted) {
          context.read<InvoiceProvider>().applyRemoteInvoiceLimits();
        }
      }());
      AdService.instance.handleResume(tier: _tier);
      if (mounted) {
        context.read<SubscriptionService>().refreshEntitlementsFromStore(silent: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _tier = context.watch<InvoiceProvider>().featureTier;
    return widget.child;
  }
}
