import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_config.dart';
import '../l10n/app_strings.dart';
import '../providers/invoice_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/auth_service.dart';

Future<void> openAccountDeletionWebPage() async {
  final uri = Uri.parse(AppConfig.accountDeletionWebUrl);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

Future<void> showDeleteAccountDialog(BuildContext context) async {
  final strings = context.l10n;
  final auth = context.read<AuthService>();
  if (!auth.isSignedIn) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.deleteAccountTitle),
        content: Text(strings.deleteAccountSignInRequired),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAccountDeletionWebPage();
            },
            child: Text(strings.deleteAccountWeb),
          ),
        ],
      ),
    );
    return;
  }

  final uid = auth.currentUser?.uid ?? '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.deleteAccountBody),
          if (uid.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              strings.deleteAccountUidHint(uid),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(strings.deleteAccountConfirm),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final provider = context.read<InvoiceProvider>();
  final result = await AccountDeletionService.instance.deleteSignedInAccount(
    invoiceProvider: provider,
  );

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (result.ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.deleteAccountSuccess)),
    );
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error!)),
    );
  }
}
