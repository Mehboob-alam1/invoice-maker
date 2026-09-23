import '../core/constants/subscription_products.dart';
import 'business_profile.dart';
import 'subscription_tier.dart';

class UserSubscriptionRecord {
  const UserSubscriptionRecord({
    required this.tier,
    this.productId,
    this.platform = 'google_play',
    this.purchaseId,
  });

  final SubscriptionTier tier;
  final String? productId;
  final String platform;
  final String? purchaseId;

  bool get isPro => tier == SubscriptionTier.pro;

  factory UserSubscriptionRecord.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserSubscriptionRecord(tier: SubscriptionTier.free);
    SubscriptionTier tier = SubscriptionTier.free;
    final tierRaw = map['tier'] as String?;
    if (tierRaw != null) {
      tier = SubscriptionTier.fromStorage(tierRaw);
    } else if (map['isPro'] as bool? ?? false) {
      tier = SubscriptionTier.pro;
    }
    final productId = map['productId'] as String?;
    if (tier == SubscriptionTier.free && productId != null) {
      tier = SubscriptionProducts.tierForProductId(productId) ?? SubscriptionTier.free;
    }
    return UserSubscriptionRecord(
      tier: tier,
      productId: productId,
      platform: map['platform'] as String? ?? 'google_play',
      purchaseId: map['purchaseId'] as String?,
    );
  }
}

class UserAccountSnapshot {
  const UserAccountSnapshot({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.business = const BusinessProfileRecord(),
    this.languageCode,
    this.subscription = const UserSubscriptionRecord(tier: SubscriptionTier.free),
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final BusinessProfileRecord business;
  final String? languageCode;
  final UserSubscriptionRecord subscription;

  factory UserAccountSnapshot.fromFirestore(String uid, Map<String, dynamic> data) {
    final topTier = data['subscriptionTier'] as String?;
    var subscription = UserSubscriptionRecord.fromMap(
      data['subscription'] as Map<String, dynamic>?,
    );
    if (topTier != null) {
      subscription = UserSubscriptionRecord(
        tier: SubscriptionTier.fromStorage(topTier),
        productId: subscription.productId,
        platform: subscription.platform,
        purchaseId: subscription.purchaseId,
      );
    }
    final prefs = data['preferences'] as Map<String, dynamic>?;
    return UserAccountSnapshot(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['googlePhotoUrl'] as String? ?? data['photoUrl'] as String?,
      business: BusinessProfileRecord.fromMap(data['business'] as Map<String, dynamic>?),
      languageCode: prefs?['languageCode'] as String?,
      subscription: subscription,
    );
  }
}
