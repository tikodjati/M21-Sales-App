import 'payment_model.dart';

class OrderItemModel {
  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final String unit; // 'pcs', 'pack', 'box'
  int quantity;
  final double unitPrice;
  bool isDiscountRequested; // Toggle ON/OFF oleh Sales
  double discountPercentage; // Ditentukan oleh Admin
  double discountAmount;
  double subtotal;

  OrderItemModel({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.isDiscountRequested = false,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    required this.subtotal,
  });

  void recalculate() {
    final rawSubtotal = unitPrice * quantity;
    if (discountPercentage > 0) {
      discountAmount = rawSubtotal * (discountPercentage / 100);
    }
    subtotal = rawSubtotal - discountAmount;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? ''),
      productId: json['product_id'] is int ? json['product_id'] : (int.tryParse(json['product_id']?.toString() ?? '0') ?? 0),
      productName: json['product_name'] ?? json['product']?['product_name'] ?? 'Produk',
      unit: json['unit']?.toString() ?? 'pcs',
      quantity: json['quantity'] is int ? json['quantity'] : (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1),
      unitPrice: (json['unit_price'] is num)
          ? (json['unit_price'] as num).toDouble()
          : (double.tryParse(json['unit_price']?.toString() ?? '0.0') ?? 0.0),
      isDiscountRequested: json['is_discount_requested'] == 1 || json['is_discount_requested'] == true,
      discountPercentage: (json['discount_percentage'] is num)
          ? (json['discount_percentage'] as num).toDouble()
          : (double.tryParse(json['discount_percentage']?.toString() ?? '0.0') ?? 0.0),
      discountAmount: (json['discount_amount'] is num)
          ? (json['discount_amount'] as num).toDouble()
          : (double.tryParse(json['discount_amount']?.toString() ?? '0.0') ?? 0.0),
      subtotal: (json['subtotal'] is num)
          ? (json['subtotal'] as num).toDouble()
          : (double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'is_discount_requested': isDiscountRequested,
      'discount_percentage': discountPercentage,
      'discount_amount': discountAmount,
      'subtotal': subtotal,
    };
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final String? salesName;
  final int storeId;
  final String? storeName;
  final int? visitId;
  final double totalAmount;
  final String orderStatus; // 'approved', 'processing', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final PaymentModel? payment;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.salesName,
    required this.storeId,
    this.storeName,
    this.visitId,
    required this.totalAmount,
    required this.orderStatus,
    this.notes,
    required this.createdAt,
    this.items = const [],
    this.payment,
  });

  bool get isCancelled => orderStatus.toLowerCase() == 'cancelled';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? json['order_items'] as List? ?? [];
    List<OrderItemModel> itemsList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => OrderItemModel.fromJson(e))
        .toList();

    return OrderModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      orderNumber: json['order_number']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] : (int.tryParse(json['user_id']?.toString() ?? '0') ?? 0),
      salesName: json['sales_name'] ?? json['user']?['name'],
      storeId: json['store_id'] is int ? json['store_id'] : (int.tryParse(json['store_id']?.toString() ?? '0') ?? 0),
      storeName: json['store_name'] ?? json['store']?['store_name'] ?? 'Toko',
      visitId: json['visit_id'] is int ? json['visit_id'] : int.tryParse(json['visit_id']?.toString() ?? ''),
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : (double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0),
      orderStatus: json['order_status']?.toString() ?? 'approved',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      items: itemsList,
      payment: (json['payment'] is Map<String, dynamic>)
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}
