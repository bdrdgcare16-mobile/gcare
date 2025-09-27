// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class LocationService {
  static const double _requiredAccuracy = 15.0; // meters
  static const int _maxAttempts = 3;
  static const Duration _timeout = Duration(seconds: 20);

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check and request location permissions
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get best possible position with multiple fallbacks
  Future<Position> getBestPosition() async {
    if (!await _checkPermissions()) {
      throw Exception('Location permissions not granted');
    }

    Position? bestPosition;
    double bestAccuracy = double.infinity;

    // Try getting position with different strategies
    for (int i = 0; i < _maxAttempts; i++) {
      try {
        final position = await _getPositionWithStrategy(i);
        
        if (position.accuracy <= _requiredAccuracy) {
          return position; // Return early if we get accurate enough position
        }

        // Keep track of best position so far
        if (position.accuracy < bestAccuracy) {
          bestPosition = position;
          bestAccuracy = position.accuracy;
        }
      } catch (e) {
        print('Location attempt ${i + 1} failed: $e');
      }

      // Add a small delay between attempts
      if (i < _maxAttempts - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // If we have a position (even if not perfect), return it
    if (bestPosition != null) {
      return bestPosition;
    }

    // As last resort, try getting last known position
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
    } catch (e) {
      print('Failed to get last known position: $e');
    }

    throw Exception('Could not obtain accurate location');
  }

  // Different strategies for different attempt numbers
  Future<Position> _getPositionWithStrategy(int attempt) async {
    switch (attempt) {
      case 0:
        // First try: High accuracy with short timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      case 1:
        // Second try: Best accuracy with medium timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 15),
        );
      default:
        // Final try: Best for navigation with longer timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: _timeout,
        );
    }
  }

  // Get address from coordinates
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
        ].where((s) => s != null).join(', ');
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown Location';
  }

  // Calculate distance between two points in meters
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}