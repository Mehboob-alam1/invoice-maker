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

  /// AI invoice generation (Premium & Pro; Free has no access).
  bool get canUseAiInvoice => this != SubscriptionTier.free;

  /// Estimated LLM tokens included per calendar month (`0` = none).
  int get monthlyAiTokenLimit => switch (this) {
        SubscriptionTier.free => 0,
        SubscriptionTier.premium => 40000,
        SubscriptionTier.pro => 150000,
      };

  /// Max estimated tokens for a single AI generation request.
  int get maxAiTokensPerRequest => switch (this) {
        SubscriptionTier.free => 0,
        SubscriptionTier.premium => 600,
        SubscriptionTier.pro => 2000,
      };

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
