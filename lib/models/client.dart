class Client {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;

  Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
  });

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      };

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}
