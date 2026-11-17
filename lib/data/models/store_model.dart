class StoreModel {
  final int id;
  final int userId;
  final String? salesName;
  final String storeName;
  final String ownerName;
  final String phoneNumber;
  final String address;
  final double latitude;
  final double longitude;
  final String? storeImageUrl;
  final DateTime? createdAt;
  final bool isMyStore;

  StoreModel({
    required this.id,
    required this.userId,
    this.salesName,
    required this.storeName,
    required this.ownerName,
    required this.phoneNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.storeImageUrl,
    this.createdAt,
    this.isMyStore = true,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final storeUserId = json['user_id'] is int
        ? json['user_id']
        : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0;

    return StoreModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: storeUserId,
      salesName: json['sales_name'] ?? json['user']?['name'],
      storeName: json['store_name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      storeImageUrl: json['store_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isMyStore: currentUserId != null ? (storeUserId == currentUserId) : (json['is_my_store'] ?? true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_name': storeName,
      'owner_name': ownerName,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'store_image_url': storeImageUrl,
    };
  }
}
