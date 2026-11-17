import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  /// Mendeteksi host backend secara otomatis:
  /// - Android Emulator: 10.0.2.2
  /// - Windows Desktop / Web Browser: 127.0.0.1
  static String get host {
    if (kIsWeb) return '127.0.0.1';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return '127.0.0.1';
  }

  static String get baseUrl => 'http://$host:8000/api';
  static String get storageUrl => 'http://$host:8000/storage';

  // Auth
  static String get login => '$baseUrl/login';
  static String get logout => '$baseUrl/logout';
  static String get profile => '$baseUrl/profile';

  // Stores
  static String get stores => '$baseUrl/stores';
  static String storeDetail(int id) => '$baseUrl/stores/$id';

  // Visits & Check-in
  static String get checkIn => '$baseUrl/visits/check-in';

  // Products
  static String get products => '$baseUrl/products';

  // Orders
  static String get orders => '$baseUrl/orders';
  static String orderDetail(int id) => '$baseUrl/orders/$id';
  static String updateOrder(int id) => '$baseUrl/orders/$id';
  static String cancelOrder(int id) => '$baseUrl/orders/$id/cancel';

  // Bank Account Info
  static const String briAccountNumber = '300601003045505';
  static const String briAccountName = 'PT M21 Corporation';
}
