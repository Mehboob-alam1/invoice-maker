import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Opens the loading overlay. Do **not** await this future — it completes only when dismissed.
void showLoadingAdDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final strings = AppStrings.read(ctx);
      return PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    strings.loadingAd,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void dismissLoadingAdDialog(BuildContext context) {
  if (!context.mounted) return;
  final nav = Navigator.of(context, rootNavigator: true);
  if (nav.canPop()) nav.pop();
}
