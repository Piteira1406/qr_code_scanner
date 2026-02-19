import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service responsible for handling GPS location functionality.
class LocationService {
  /// Maximum allowed distance in meters for a valid check-in.
  static const double maxCheckInDistanceMeters = 100.0;

  StreamSubscription<Position>? _positionSubscription;

  /// Checks and requests location permissions.
  /// Returns true if permissions are granted.
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
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

  /// Gets the current position of the device.
  /// Throws an exception if permissions are not granted.
  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      throw LocationServiceException(
        'Permissões de localização não concedidas',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      throw LocationServiceException('Não foi possível obter a localização');
    }
  }

  /// Creates a stream for continuous location updates.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculates the distance in meters between two coordinates.
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Checks if the user is within the allowed radius of the event location.
  bool isWithinRange(
    double userLatitude,
    double userLongitude,
    double eventLatitude,
    double eventLongitude,
  ) {
    final distance = calculateDistance(
      userLatitude,
      userLongitude,
      eventLatitude,
      eventLongitude,
    );
    return distance <= maxCheckInDistanceMeters;
  }

  /// Validates if the user's current location is within range of the event.
  /// Returns a tuple with (isValid, distance, position).
  Future<LocationValidationResult> validateLocation({
    required double eventLatitude,
    required double eventLongitude,
  }) async {
    final position = await getCurrentPosition();
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      eventLatitude,
      eventLongitude,
    );
    final isValid = distance <= maxCheckInDistanceMeters;

    return LocationValidationResult(
      isValid: isValid,
      distance: distance,
      position: position,
    );
  }

  /// Cancels any active position stream subscription.
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

/// Result of a location validation check.
class LocationValidationResult {
  final bool isValid;
  final double distance;
  final Position position;

  LocationValidationResult({
    required this.isValid,
    required this.distance,
    required this.position,
  });

  @override
  String toString() =>
      'LocationValidationResult(isValid: $isValid, distance: ${distance.toStringAsFixed(2)}m)';
}

/// Exception thrown when location services fail.
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
