import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService {
  static Position? _currentPosition;
  static bool _locationPermissionDenied = false;

  /// Get current user location with permission handling
  static Future<Position?> getCurrentLocation() async {
    if (_locationPermissionDenied) return null;
    if (_currentPosition != null) return _currentPosition;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationPermissionDenied = true;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationPermissionDenied = true;
        return null;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} م';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} كم';
    }
  }

  /// Reset cached position (call when user manually refreshes)
  static void resetPosition() {
    _currentPosition = null;
  }

  /// Reset permission denial flag (call when user wants to retry)
  static void resetPermissionDenial() {
    _locationPermissionDenied = false;
  }

  static bool get isPermissionDenied => _locationPermissionDenied;
}
