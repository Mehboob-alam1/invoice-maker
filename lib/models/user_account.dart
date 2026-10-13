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

  factory UserAccountSnapshot.fromDatabaseRow(Map<String, dynamic> row) {
    return UserAccountSnapshot(
      uid: row['id'] as String,
      email: row['email'] as String?,
      displayName: row['display_name'] as String?,
      photoUrl: row['google_photo_url'] as String? ?? row['photo_url'] as String?,
      business: BusinessProfileRecord(
        name: row['business_name'] as String? ?? '',
        email: row['business_email'] as String? ?? '',
        phone: row['business_phone'] as String? ?? '',
        address: row['business_address'] as String? ?? '',
        taxId: row['business_tax_id'] as String? ?? '',
        logoUrl: row['business_logo_url'] as String?,
      ),
      languageCode: row['language_code'] as String?,
      subscription: UserSubscriptionRecord(
        tier: SubscriptionTier.fromStorage(row['subscription_tier'] as String?),
        productId: row['subscription_product_id'] as String?,
        platform: row['subscription_platform'] as String? ?? 'google_play',
        purchaseId: row['subscription_purchase_id'] as String?,
      ),
    );
  }
}
