import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_dialog.dart';
import '../navigation/app_page_route.dart';
import '../screens/subscription/subscription_plans_screen.dart';
import 'subscription_service.dart';

/// After Play reports an expired subscription, nudge user to plans once.
class SubscriptionRenewalPrompt {
  SubscriptionRenewalPrompt._();

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(SubscriptionService.pendingRenewPromptKey) != true) return;
    await prefs.setBool(SubscriptionService.pendingRenewPromptKey, false);
    if (!context.mounted) return;

    final strings = context.l10n;
    final renew = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.workspace_premium_rounded,
        title: strings.subscriptionExpiredTitle,
        message: strings.subscriptionExpiredBody,
        actions: [
          AppDialogAction(
            label: strings.viewPlans,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          AppDialogAction(
            label: strings.notNow,
            style: AppDialogActionStyle.text,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
    if (renew == true && context.mounted) {
      Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
    }
  }
}
