import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static const double maxCheckInRadiusMeters = 100.0;

  /// Meminta izin lokasi dan mengembalikan posisi terkini perangkat
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Menghitung jarak (dalam meter) antara koordinat sales dan koordinat toko
  static double calculateDistanceInMeters({
    required double currentLat,
    required double currentLong,
    required double targetLat,
    required double targetLong,
  }) {
    return Geolocator.distanceBetween(
      currentLat,
      currentLong,
      targetLat,
      targetLong,
    );
  }

  /// Memvalidasi apakah posisi sales masih dalam radius toleransi check-in (<= 100m)
  static bool isWithinCheckInRadius({
    required double currentLat,
    required double currentLong,
    required double targetLat,
    required double targetLong,
  }) {
    final distance = calculateDistanceInMeters(
      currentLat: currentLat,
      currentLong: currentLong,
      targetLat: targetLat,
      targetLong: targetLong,
    );
    return distance <= maxCheckInRadiusMeters;
  }
}
