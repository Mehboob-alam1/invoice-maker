import '../../models/subscription_tier.dart';

/// Play Console / App Store subscription product IDs.
///
/// Create **two** subscription groups (or one group with two base plans each):
/// - **Premium**: `invoice_maker_premium_monthly`, `invoice_maker_premium_yearly`
/// - **Pro**: `invoice_maker_pro_monthly`, `invoice_maker_pro_yearly`
///
/// Suggested list prices (set in Play Console — shown live via [ProductDetails.price]):
/// | Plan     | Monthly | Yearly (≈33% off) |
/// | Premium  | $4.99   | $39.99            |
/// | Pro      | $9.99   | $79.99              |
class SubscriptionProducts {
  SubscriptionProducts._();

  static const premiumMonthly = 'invoice_maker_premium_monthly';
  static const premiumYearly = 'invoice_maker_premium_yearly';
  static const proMonthly = 'invoice_maker_pro_monthly';
  static const proYearly = 'invoice_maker_pro_yearly';

  /// Legacy weekly Pro SKU (maps to Pro tier).
  static const legacyProWeekly = 'invoice_maker_pro_weekly';

  static const Set<String> premiumProductIds = {premiumMonthly, premiumYearly};
  static const Set<String> proProductIds = {
    proMonthly,
    proYearly,
    legacyProWeekly,
  };

  static const Set<String> allPaidProductIds = {
    ...premiumProductIds,
    ...proProductIds,
  };

  static SubscriptionTier? tierForProductId(String productId) {
    if (proProductIds.contains(productId)) return SubscriptionTier.pro;
    if (premiumProductIds.contains(productId)) return SubscriptionTier.premium;
    return null;
  }

  static String productIdFor(SubscriptionTier tier, {required bool yearly}) {
    return switch (tier) {
      SubscriptionTier.free => '',
      SubscriptionTier.premium => yearly ? premiumYearly : premiumMonthly,
      SubscriptionTier.pro => yearly ? proYearly : proMonthly,
    };
  }
}
