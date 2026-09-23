import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import 'native_ad_widget.dart';

/// Puts a compact native ad under [child]. Use one [NativeAdHost] per route so each screen loads its own ad.
class NativeAdHost extends StatelessWidget {
  final Widget? child;
  final String adScopeKey;

  const NativeAdHost({
    super.key,
    required this.child,
    required this.adScopeKey,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNative = context.watch<InvoiceProvider>().subscriptionTier.showNativeAds;

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: !keyboardOpen,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        if (!keyboardOpen && showNative) NativeAdWidget(key: ValueKey('native_ad_$adScopeKey')),
      ],
    );
  }
}
