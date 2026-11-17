import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/product_model.dart';
import '../data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<ProductModel> _products = [];
  final List<OrderItemModel> _cartItems = [];
  List<OrderModel> _orders = [];

  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider(this._apiClient);

  List<ProductModel> get products => _products;
  List<OrderItemModel> get cartItems => _cartItems;
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get cartTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Mengambil katalog produk aktif dari admin
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.products);
      if (response.statusCode == 200) {
        final List rawData = response.data['data'] ?? response.data;
        _products = rawData.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal memuat produk.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tambah item ke keranjang pesanan
  void addToCart({
    required ProductModel product,
    required String unit, // 'pcs', 'pack', 'box'
    required int quantity,
    required bool isDiscountRequested, // Sesuai SRS: Toggle ON/OFF
  }) {
    final unitPrice = product.getPriceByUnit(unit);
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id && item.unit.toLowerCase() == unit.toLowerCase(),
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
      _cartItems[existingIndex].isDiscountRequested = isDiscountRequested;
      _cartItems[existingIndex].recalculate();
    } else {
      final newItem = OrderItemModel(
        productId: product.id,
        productName: product.productName,
        unit: unit,
        quantity: quantity,
        unitPrice: unitPrice,
        isDiscountRequested: isDiscountRequested,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        subtotal: unitPrice * quantity,
      );
      _cartItems.add(newItem);
    }
    notifyListeners();
  }

  /// Toggle permintaan diskon pada item keranjang
  void toggleDiscountRequest(int index, bool value) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].isDiscountRequested = value;
      notifyListeners();
    }
  }

  /// Ubah kuantitas item keranjang
  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
        _cartItems[index].recalculate();
      }
      notifyListeners();
    }
  }

  /// Hapus item dari keranjang
  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Mengambil daftar riwayat pesanan
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.orders);
      if (response.statusCode == 200) {
        final List rawData = response.data['data'] ?? response.data;
        _orders = rawData.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal memuat pesanan.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit pesanan (Auto-approved)
  Future<bool> submitOrder({
    required int storeId,
    int? visitId,
    required String paymentMethod, // 'cash', 'tempo', 'transfer'
    File? proofOfTransferImage,
  }) async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Keranjang belanja masih kosong.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> payload = {
        'store_id': storeId,
        'visit_id': ?visitId,
        'payment_method': paymentMethod,
        'items': _cartItems.map((item) => item.toJson()).toList(),
      };

      if (paymentMethod == 'transfer' && proofOfTransferImage != null) {
        String fileName = proofOfTransferImage.path.split('/').last;
        payload['proof_of_transfer'] = await MultipartFile.fromFile(
          proofOfTransferImage.path,
          filename: fileName,
        );
      }

      final dynamic data = (paymentMethod == 'transfer' && proofOfTransferImage != null)
          ? FormData.fromMap(payload)
          : payload;

      final response = await _apiClient.dio.post(
        ApiEndpoints.orders,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        clearCart();
        await fetchOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal mengirimkan pesanan.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Kesalahan saat menyimpan pesanan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Membatalkan pesanan (sesuai hak sales BR-06)
  Future<bool> cancelOrder(int orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(ApiEndpoints.cancelOrder(orderId));
      if (response.statusCode == 200) {
        await fetchOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Gagal membatalkan order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
