import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ad_remote_config.dart';
import '../l10n/app_strings.dart';
import '../providers/invoice_provider.dart';
import '../services/push_notification_service.dart';

/// Explains notifications in the app, then asks the system only if the user agrees.
class NotificationPrompt {
  NotificationPrompt._();

  static const _opensKey = 'notification_prompt_home_opens';
  static const _answeredKey = 'notification_prompt_answered';

  static Future<void> maybeAsk(BuildContext context) async {
    if (!AdRemoteConfig.instance.pushNotificationsEnabled) return;
    if (await PushNotificationService.instance.notificationsAreEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_answeredKey) == true) return;

    final opens = (prefs.getInt(_opensKey) ?? 0) + 1;
    await prefs.setInt(_opensKey, opens);
    if (!context.mounted) return;

    final invoiceCount = context.read<InvoiceProvider>().unpaidInvoices.length +
        context.read<InvoiceProvider>().paidInvoices.length;
    final ready = opens >= 3 || (opens >= 2 && invoiceCount > 0);
    if (!ready) return;

    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final strings = ctx.l10n;
        final theme = Theme.of(ctx);
        return AlertDialog(
          icon: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary, size: 36),
          title: Text(strings.t('notificationPromptTitle')),
          content: Text(strings.t('notificationPromptBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.t('notificationPromptLater')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(strings.t('notificationPromptAllow')),
            ),
          ],
        );
      },
    );
    await prefs.setBool(_answeredKey, true);
    if (allow == true) {
      await PushNotificationService.instance.requestPermissionFromSettings();
    }
  }
}
