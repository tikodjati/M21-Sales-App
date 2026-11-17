class ProductModel {
  final int id;
  final String productName;
  final double pricePcs;
  final double pricePack;
  final double priceBox;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.productName,
    required this.pricePcs,
    required this.pricePack,
    required this.priceBox,
    this.isActive = true,
  });

  double getPriceByUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'box':
        return priceBox;
      case 'pack':
        return pricePack;
      case 'pcs':
      default:
        return pricePcs;
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      productName: json['product_name'] ?? '',
      pricePcs: (json['price_pcs'] is num)
          ? (json['price_pcs'] as num).toDouble()
          : double.tryParse(json['price_pcs']?.toString() ?? '0.0') ?? 0.0,
      pricePack: (json['price_pack'] is num)
          ? (json['price_pack'] as num).toDouble()
          : double.tryParse(json['price_pack']?.toString() ?? '0.0') ?? 0.0,
      priceBox: (json['price_box'] is num)
          ? (json['price_box'] as num).toDouble()
          : double.tryParse(json['price_box']?.toString() ?? '0.0') ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'price_pcs': pricePcs,
      'price_pack': pricePack,
      'price_box': priceBox,
      'is_active': isActive,
    };
  }
}
