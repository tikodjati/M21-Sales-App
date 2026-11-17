class ApiEndpoints {
  // Ganti IP ini sesuai host backend (10.0.2.2 untuk emulator Android, atau IP LAN untuk HP fisik)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String storageUrl = 'http://10.0.2.2:8000/storage';

  // Auth
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String profile = '$baseUrl/profile';

  // Stores
  static const String stores = '$baseUrl/stores';
  static String storeDetail(int id) => '$baseUrl/stores/$id';

  // Visits & Check-in
  static const String checkIn = '$baseUrl/visits/check-in';

  // Products
  static const String products = '$baseUrl/products';

  // Orders
  static const String orders = '$baseUrl/orders';
  static String orderDetail(int id) => '$baseUrl/orders/$id';
  static String updateOrder(int id) => '$baseUrl/orders/$id';
  static String cancelOrder(int id) => '$baseUrl/orders/$id/cancel';

  // Bank Account Info
  static const String briAccountNumber = '300601003045505';
  static const String briAccountName = 'PT M21 Corporation';
}
