import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/utils/location_helper.dart';
import '../data/models/store_model.dart';

class VisitProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  bool _isLoading = false;
  String? _errorMessage;
  int? _activeVisitId;
  StoreModel? _activeStore;

  VisitProvider(this._apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get activeVisitId => _activeVisitId;
  StoreModel? get activeStore => _activeStore;
  bool get hasActiveVisit => _activeVisitId != null && _activeStore != null;

  /// Melakukan validasi check-in kehadiran di toko dengan verifikasi GPS radius (<= 100m)
  Future<bool> checkIn(StoreModel store) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ambil koordinat GPS perangkat sales terkini
      final currentPos = await LocationHelper.getCurrentPosition();
      if (currentPos == null) {
        _errorMessage = 'Tidak dapat mendeteksi lokasi GPS Anda. Pastikan layanan GPS diaktifkan.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Hitung jarak ke toko
      final distance = LocationHelper.calculateDistanceInMeters(
        currentLat: currentPos.latitude,
        currentLong: currentPos.longitude,
        targetLat: store.latitude,
        targetLong: store.longitude,
      );

      // 3. Verifikasi batasan radius 100 meter (BR-03)
      if (distance > LocationHelper.maxCheckInRadiusMeters) {
        _errorMessage =
            'Check-in gagal! Anda berada ${distance.toStringAsFixed(1)} meter dari toko. '
            'Batas toleransi maksimal adalah 100 meter.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 4. Kirim log check-in ke API backend
      final response = await _apiClient.dio.post(
        ApiEndpoints.checkIn,
        data: {
          'store_id': store.id,
          'checkin_latitude': currentPos.latitude,
          'checkin_longitude': currentPos.longitude,
          'distance_meters': distance,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _activeVisitId = response.data['visit_id'] ?? response.data['id'] ?? 1;
        _activeStore = store;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Check-in gagal diproses oleh server.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Terjadi kesalahan jaringan saat check-in.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal melakukan check-in: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearActiveVisit() {
    _activeVisitId = null;
    _activeStore = null;
    notifyListeners();
  }
}
