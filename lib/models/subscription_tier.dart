/// App subscription level (Free is default; Premium & Pro from Play/App Store).
enum SubscriptionTier {
  free,
  premium,
  pro;

  String get storageKey => name;

  /// Daily invoice cap; `-1` = unlimited.
  int get dailyInvoiceLimit => switch (this) {
        SubscriptionTier.free => 3,
        SubscriptionTier.premium => 10,
        SubscriptionTier.pro => -1,
      };

  bool get showNativeAds => this != SubscriptionTier.pro;

  bool get showInterstitialAds => this == SubscriptionTier.free;

  bool get showAppOpenAds => this != SubscriptionTier.pro;

  bool get reducedAppOpenAds => this == SubscriptionTier.premium;

  bool get canUsePremiumTemplates => this != SubscriptionTier.free;

  bool get canCustomizeTemplates => this == SubscriptionTier.pro;

  /// Free plan includes this many AI generations per month (~[tokensPerAiCredit] tokens each).
  static const freeMonthlyAiCredits = 3;

  /// Approximate token cost counted as one AI credit in UI.
  static const tokensPerAiCredit = 600;

  /// AI invoice generation (all tiers; Free has a small monthly allowance).
  bool get canUseAiInvoice => monthlyAiTokenLimit > 0;

  /// Estimated LLM tokens included per calendar month (`0` = none).
  int get monthlyAiTokenLimit => switch (this) {
        SubscriptionTier.free => freeMonthlyAiCredits * tokensPerAiCredit,
        SubscriptionTier.premium => 40000,
        SubscriptionTier.pro => 150000,
      };

  /// Max estimated tokens for a single AI generation request.
  int get maxAiTokensPerRequest => switch (this) {
        SubscriptionTier.free => tokensPerAiCredit,
        SubscriptionTier.premium => 600,
        SubscriptionTier.pro => 2000,
      };

  /// Whole AI credits included per month (for display on Free).
  int get monthlyAiCredits => (monthlyAiTokenLimit / tokensPerAiCredit).ceil();

  /// Rough character cap for the prompt (≈4 chars per token).
  int get maxAiInputCharacters => maxAiTokensPerRequest * 4;

  static SubscriptionTier fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return SubscriptionTier.free;
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => SubscriptionTier.free,
    );
  }
}
