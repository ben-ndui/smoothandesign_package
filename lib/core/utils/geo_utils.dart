import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitaires pour les calculs géographiques.
class GeoUtils {
  GeoUtils._();

  /// Rayon de la Terre en mètres.
  static const double earthRadius = 6371000;

  /// Calcule la distance en mètres entre deux points GPS (Haversine).
  static double calculateDistance(GeoPoint point1, GeoPoint point2) {
    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Vérifie si un point est dans un rayon donné.
  static bool isWithinRadius(GeoPoint point, GeoPoint center, double radiusMeters) {
    return calculateDistance(point, center) <= radiusMeters;
  }

  /// Formate une distance en texte lisible.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)} km';
      } else {
        return '${km.round()} km';
      }
    }
  }

  /// Vérifie si des coordonnées sont valides.
  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Crée un GeoPoint à partir de coordonnées.
  static GeoPoint? createGeoPoint(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    if (!isValidCoordinates(latitude, longitude)) return null;
    return GeoPoint(latitude, longitude);
  }

  /// Calcule le centre de plusieurs points.
  static GeoPoint? calculateCenter(List<GeoPoint> points) {
    if (points.isEmpty) return null;

    double latSum = 0;
    double lonSum = 0;

    for (final point in points) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }

    return GeoPoint(latSum / points.length, lonSum / points.length);
  }

  /// Calcule le cap (bearing) entre deux points en degrés.
  static double calculateBearing(GeoPoint from, GeoPoint to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }
}
