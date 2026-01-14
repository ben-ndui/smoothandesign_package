import 'package:geolocator/geolocator.dart';

/// Simple latitude/longitude class to avoid google_maps_flutter dependency.
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Service de gestion de la géolocalisation.
///
/// Singleton qui gère les permissions et la position de l'utilisateur.
///
/// Usage:
/// ```dart
/// final location = LocationService();
///
/// // Vérifier les permissions
/// final permission = await location.checkPermission();
///
/// // Obtenir la position actuelle
/// final position = await location.getCurrentPosition();
///
/// // Stream de positions
/// location.getPositionStream().listen((position) {
///   print('New position: ${position.latitude}, ${position.longitude}');
/// });
/// ```
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;

  /// Default position (Paris) if location not available.
  static const LatLng defaultPosition = LatLng(48.8566, 2.3522);

  /// Default distance filter for position stream (meters).
  static const int defaultDistanceFilter = 50;

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position with permission handling.
  ///
  /// Returns null if location services are disabled or permission denied.
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
      return _lastKnownPosition;
    } catch (e) {
      return _lastKnownPosition;
    }
  }

  /// Get current position as LatLng.
  ///
  /// Returns [defaultPosition] if unable to get current location.
  Future<LatLng> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return defaultPosition;
  }

  /// Get last known position.
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Get last known LatLng or default.
  LatLng get lastKnownLatLng {
    if (_lastKnownPosition != null) {
      return LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude);
    }
    return defaultPosition;
  }

  /// Stream position updates.
  ///
  /// [distanceFilter] - Minimum distance (in meters) before update is emitted.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = defaultDistanceFilter,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculate distance between two points in meters.
  double distanceBetween(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculate distance from current position to a point.
  double? distanceFromCurrent(LatLng destination) {
    if (_lastKnownPosition == null) return null;
    return distanceBetween(lastKnownLatLng, destination);
  }

  /// Format distance for display.
  ///
  /// Returns "X m" for distances < 1000m, "X.X km" otherwise.
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Open app settings (useful when permission is denied forever).
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
