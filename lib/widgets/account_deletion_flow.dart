import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/invoice_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/auth_service.dart';
import 'app_dialog.dart';

Future<void> showDeleteAccountDialog(BuildContext context) async {
  final strings = context.l10n;
  final auth = context.read<AuthService>();
  if (!auth.isSignedIn || auth.currentUser?.isAnonymous == true) {
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.login_rounded,
        title: strings.deleteAccountTitle,
        message: strings.deleteAccountSignInRequired,
        actions: [
          AppDialogAction(
            label: strings.signInWithGoogle,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          AppDialogAction(
            label: strings.cancel,
            style: AppDialogActionStyle.text,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    final signedIn = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (!signedIn || auth.currentUser == null || auth.currentUser!.isAnonymous) {
      final detail = auth.lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail ?? strings.backupSignInCancelled)),
      );
      return;
    }
  }

  final uid = auth.currentUser?.uid ?? '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.person_off_rounded,
      tone: AppDialogTone.danger,
      title: strings.deleteAccountTitle,
      message: strings.deleteAccountBody,
      body: uid.isEmpty
          ? null
          : Text(
              strings.deleteAccountUidHint(uid),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
      actions: [
        AppDialogAction(
          label: strings.deleteAccountConfirm,
          destructive: true,
          onPressed: () => Navigator.pop(ctx, true),
        ),
        AppDialogAction(
          label: strings.cancel,
          style: AppDialogActionStyle.text,
          onPressed: () => Navigator.pop(ctx, false),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: scheme.surface,
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(28),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      );
    },
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
