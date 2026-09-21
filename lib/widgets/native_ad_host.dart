import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import 'native_ad_widget.dart';

/// Wraps every route with a native ad pinned to the bottom of the screen.
class NativeAdHost extends StatelessWidget {
  final Widget? child;

  const NativeAdHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hideForPro = context.watch<InvoiceProvider>().isPro;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: !hideForPro && !keyboardOpen,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        if (!hideForPro && !keyboardOpen) const NativeAdWidget(),
      ],
    );
  }
}
