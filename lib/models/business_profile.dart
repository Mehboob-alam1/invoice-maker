/// Business details stored under `users/{uid}/business` in Firestore.
/// [logoUrl] is reserved for a future Pro feature — not the Google account photo.
class BusinessProfileRecord {
  const BusinessProfileRecord({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.taxId = '',
    this.logoUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String? logoUrl;

  bool get hasAnyField =>
      name.isNotEmpty || email.isNotEmpty || phone.isNotEmpty || address.isNotEmpty || taxId.isNotEmpty;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'taxId': taxId,
        'logoUrl': logoUrl,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory BusinessProfileRecord.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BusinessProfileRecord();
    return BusinessProfileRecord(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      taxId: map['taxId'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
    );
  }
}
