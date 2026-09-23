import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_config.dart';
import '../l10n/app_strings.dart';
import '../screens/invoice/invoice_preview_edit_screen.dart';
import '../widgets/native_ad_host.dart';

/// Slide-up route for invoice create / preview flow.
Route<T> appInvoiceFlowRoute<T>(
  Widget page, {
  required String adScopeKey,
  bool showNativeAd = true,
}) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: adScopeKey),
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      final child = showNativeAd && AdConfig.isSupported
          ? NativeAdHost(adScopeKey: adScopeKey, child: page)
          : page;
      return child;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Clears the create-invoice stack and opens preview (Home stays underneath).
Future<void> navigateAfterInvoiceCreated(BuildContext context, String invoiceId) async {
  HapticFeedback.mediumImpact();
  await Navigator.of(context).pushAndRemoveUntil(
    appInvoiceFlowRoute<void>(
      InvoicePreviewEditScreen(invoiceId: invoiceId, justCreated: true),
      adScopeKey: 'invoice_preview_$invoiceId',
    ),
    (route) => route.isFirst,
  );
  if (!context.mounted) return;
  final strings = AppStrings.read(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(strings.invoiceCreatedSnackbar),
      duration: const Duration(seconds: 3),
    ),
  );
}
