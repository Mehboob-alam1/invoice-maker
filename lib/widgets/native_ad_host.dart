import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_remote_config.dart';
import '../providers/invoice_provider.dart';
import 'native_ad_widget.dart';

/// Full-width bottom native ad; [child] scrolls in the space above (not under the ad).
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
    final showNative =
        rc.adsEnabled && context.watch<InvoiceProvider>().subscriptionTier.showNativeAds;
    final showBar = !keyboardOpen && showNative;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: showBar
                ? MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: child ?? const SizedBox.shrink(),
                  )
                : child ?? const SizedBox.shrink(),
          ),
          if (showBar)
            MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: Align(
                alignment: Alignment.bottomCenter,
                widthFactor: 1,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: NativeAdWidget(key: ValueKey('native_ad_$adScopeKey')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
