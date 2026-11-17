import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/store_model.dart';

class StoreProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  List<StoreModel> _stores = [];
  bool _isLoading = false;
  String? _errorMessage;

  StoreProvider(this._apiClient);

  List<StoreModel> get stores => _stores;
  List<StoreModel> get myStores => _stores.where((s) => s.isMyStore).toList();
  List<StoreModel> get otherStores => _stores.where((s) => !s.isMyStore).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Mengambil seluruh data toko (toko milik sales + toko sales lain untuk peta teritori)
  Future<void> fetchStores({int? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.stores);
      if (response.statusCode == 200) {
        final List rawData = response.data['data'] ?? response.data;
        _stores = rawData
            .map((item) => StoreModel.fromJson(item as Map<String, dynamic>, currentUserId: currentUserId))
            .toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal memuat daftar toko.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pendaftaran toko baru dengan dukungan upload foto dan koordinat
  Future<bool> registerStore({
    required String storeName,
    required String ownerName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
    File? storeImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> data = {
        'store_name': storeName,
        'owner_name': ownerName,
        'phone_number': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (storeImage != null) {
        String fileName = storeImage.path.split('/').last;
        data['store_image'] = await MultipartFile.fromFile(
          storeImage.path,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap(data);

      final response = await _apiClient.dio.post(
        ApiEndpoints.stores,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newStore = StoreModel.fromJson(response.data['data'] ?? response.data, currentUserId: null);
        _stores.insert(0, newStore);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // Deteksi duplikasi nomor telepon toko
        _errorMessage = e.response?.data?['message'] ??
            'Nomor telepon toko sudah terdaftar di sistem oleh sales lain.';
      } else {
        _errorMessage = e.response?.data?['message'] ?? 'Gagal mendaftarkan toko baru.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Kesalahan saat menyimpan toko: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
