import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import '../widgets/premium_upsell_dialog.dart';

/// Shows Premium upsell for free users with a short cooldown (not on every tap).
class PremiumUpsellService {
  PremiumUpsellService._();

  static const _lastShownKey = 'premium_upsell_last_shown_ms';
  static const _showCountKey = 'premium_upsell_show_count';
  static const _cooldown = Duration(minutes: 4);

  static bool _dialogVisible = false;

  static Future<bool> _canShow(InvoiceProvider provider) async {
    if (provider.subscriptionTier != SubscriptionTier.free) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey);
    if (last == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= _cooldown.inMilliseconds;
  }

  static Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    final count = prefs.getInt(_showCountKey) ?? 0;
    await prefs.setInt(_showCountKey, count + 1);
  }

  /// Call when free user lands on home, returns to home, or hits quota pressure.
  static Future<void> maybeShow(
    BuildContext context, {
    bool forceIfLowQuota = false,
  }) async {
    if (_dialogVisible || !context.mounted) return;
    final provider = context.read<InvoiceProvider>();
    if (provider.subscriptionTier != SubscriptionTier.free) return;

    final remaining = provider.invoicesRemainingToday;
    final lowQuota = remaining != null && remaining <= 1;
    final bypassCooldown = forceIfLowQuota || lowQuota;
    if (!bypassCooldown && !await _canShow(provider)) return;
    if (!context.mounted) return;

    _dialogVisible = true;
    try {
      await showPremiumUpsellDialog(context);
      await _markShown();
    } finally {
      _dialogVisible = false;
    }
  }
}
