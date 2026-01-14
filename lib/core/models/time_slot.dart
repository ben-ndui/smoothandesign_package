import 'package:equatable/equatable.dart';

/// Représente un créneau horaire.
///
/// Usage:
/// ```dart
/// final slot = TimeSlot(
///   start: DateTime(2024, 1, 15, 9, 0),
///   end: DateTime(2024, 1, 15, 10, 0),
///   isAvailable: true,
/// );
///
/// print(slot.durationMinutes); // 60
/// print(slot.toString()); // "9:00 - 10:00"
/// ```
class TimeSlot extends Equatable {
  final DateTime start;
  final DateTime end;
  final bool isAvailable;

  /// Données additionnelles (ex: raison d'indisponibilité).
  final Map<String, dynamic>? metadata;

  const TimeSlot({
    required this.start,
    required this.end,
    this.isAvailable = true,
    this.metadata,
  });

  /// Durée en minutes.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Durée en heures.
  double get durationHours => durationMinutes / 60;

  /// Vérifie si une DateTime est dans ce créneau.
  bool contains(DateTime dateTime) {
    return !dateTime.isBefore(start) && dateTime.isBefore(end);
  }

  /// Vérifie si ce créneau chevauche un autre.
  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return start.isBefore(otherEnd) && end.isAfter(otherStart);
  }

  /// Vérifie si ce créneau est dans le passé.
  bool get isPast => end.isBefore(DateTime.now());

  /// Vérifie si ce créneau est en cours.
  bool get isOngoing {
    final now = DateTime.now();
    return !start.isAfter(now) && end.isAfter(now);
  }

  TimeSlot copyWith({
    DateTime? start,
    DateTime? end,
    bool? isAvailable,
    Map<String, dynamic>? metadata,
  }) {
    return TimeSlot(
      start: start ?? this.start,
      end: end ?? this.end,
      isAvailable: isAvailable ?? this.isAvailable,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      '${start.hour}:${start.minute.toString().padLeft(2, '0')} - '
      '${end.hour}:${end.minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [start, end, isAvailable];
}

/// Niveau de disponibilité d'un créneau.
enum AvailabilityLevel {
  unavailable, // Indisponible
  limited, // Disponibilité limitée
  partial, // Partiellement disponible
  full, // Entièrement disponible
}

/// Créneau enrichi avec infos sur les ressources disponibles.
///
/// Usage:
/// ```dart
/// final slot = EnhancedTimeSlot(
///   start: DateTime(2024, 1, 15, 9, 0),
///   end: DateTime(2024, 1, 15, 10, 0),
///   isAvailable: true,
///   availableResources: ['engineer1', 'engineer2'],
///   totalResources: 3,
/// );
///
/// print(slot.availableCount); // 2
/// print(slot.availabilityLevel); // AvailabilityLevel.partial
/// ```
class EnhancedTimeSlot extends TimeSlot {
  /// IDs ou noms des ressources disponibles.
  final List<String> availableResources;

  /// Nombre total de ressources.
  final int totalResources;

  const EnhancedTimeSlot({
    required super.start,
    required super.end,
    required super.isAvailable,
    required this.availableResources,
    required this.totalResources,
    super.metadata,
  });

  /// Nombre de ressources disponibles.
  int get availableCount => availableResources.length;

  /// Au moins une ressource est disponible.
  bool get hasAvailableResource => availableCount > 0;

  /// Niveau de disponibilité.
  AvailabilityLevel get availabilityLevel {
    if (!isAvailable) return AvailabilityLevel.unavailable;
    if (availableCount == 0) return AvailabilityLevel.unavailable;
    if (availableCount == 1) return AvailabilityLevel.limited;
    if (availableCount < totalResources) return AvailabilityLevel.partial;
    return AvailabilityLevel.full;
  }

  /// Pourcentage de disponibilité (0-100).
  double get availabilityPercent {
    if (totalResources == 0) return 0;
    return (availableCount / totalResources) * 100;
  }

  @override
  EnhancedTimeSlot copyWith({
    DateTime? start,
    DateTime? end,
    bool? isAvailable,
    List<String>? availableResources,
    int? totalResources,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedTimeSlot(
      start: start ?? this.start,
      end: end ?? this.end,
      isAvailable: isAvailable ?? this.isAvailable,
      availableResources: availableResources ?? this.availableResources,
      totalResources: totalResources ?? this.totalResources,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props =>
      [start, end, isAvailable, availableResources, totalResources];
}
