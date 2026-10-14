import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_remote_config.dart';
import '../providers/invoice_provider.dart';
import 'native_ad_widget.dart';

/// Native ad under the page. [child] scrolls in the space above the ad.
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
    final rc = AdRemoteConfig.instance;
    final invoices = context.watch<InvoiceProvider>();
    final showNative = rc.adsEnabled && !invoices.adsHeld && invoices.featureTier.showNativeAds;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            // Keep this wrapper in place when the keyboard opens. Swapping it
            // out remounts the page and the focused field loses the keyboard.
            child: child ?? const SizedBox.shrink(),
          ),
          if (showNative)
            Offstage(
              offstage: keyboardOpen,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  8,
                  10,
                  MediaQuery.paddingOf(context).bottom + 8,
                ),
                child: NativeAdWidget(key: ValueKey('native_ad_$adScopeKey')),
              ),
            ),
        ],
      ),
    );
  }
}
