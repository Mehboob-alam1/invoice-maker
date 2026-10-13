import '../../models/subscription_tier.dart';

/// Play Console / App Store subscription product IDs.
///
/// The only plan for sale is [weekly] (`invoice_maker_weekly`).
/// The 3-day trial is configured on that Play base plan.
/// Older monthly and yearly SKUs are recognized on restore only.
class SubscriptionProducts {
  SubscriptionProducts._();

  static const premiumMonthly = 'invoice_maker_premium_monthly';
  static const premiumYearly = 'invoice_maker_premium_yearly';
  static const proMonthly = 'invoice_maker_pro_monthly';
  static const proYearly = 'invoice_maker_pro_yearly';

  /// Legacy weekly Pro SKU (maps to Pro tier).
  static const legacyProWeekly = 'invoice_maker_pro_weekly';

  /// The only plan offered in the paywall.
  static const weekly = 'invoice_maker_weekly';

  static const Set<String> premiumProductIds = {premiumMonthly, premiumYearly};
  static const Set<String> proProductIds = {
    proMonthly,
    proYearly,
    legacyProWeekly,
    weekly,
  };

  /// The only SKU queried for purchase.
  static const Set<String> storeProductIds = {weekly};

  static const Set<String> allPaidProductIds = {
    ...premiumProductIds,
    ...proProductIds,
  };

  static SubscriptionTier? tierForProductId(String productId) {
    if (proProductIds.contains(productId)) return SubscriptionTier.pro;
    if (premiumProductIds.contains(productId)) return SubscriptionTier.premium;
    return null;
  }

  static String productIdFor(SubscriptionTier tier, {bool yearly = false}) {
    if (tier == SubscriptionTier.free) return '';
    return weekly;
  }
}
