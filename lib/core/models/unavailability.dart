import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Source d'une indisponibilité.
enum UnavailabilitySource {
  google('google', 'Google Calendar'),
  apple('apple', 'Apple Calendar'),
  outlook('outlook', 'Outlook'),
  manual('manual', 'Manual');

  final String value;
  final String label;

  const UnavailabilitySource(this.value, this.label);

  static UnavailabilitySource fromString(String? value) {
    return UnavailabilitySource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UnavailabilitySource.manual,
    );
  }
}

/// Modèle générique d'indisponibilité.
///
/// Usage:
/// ```dart
/// final unavailability = Unavailability(
///   id: 'unav123',
///   entityId: 'studio456',
///   start: DateTime(2024, 1, 15, 9, 0),
///   end: DateTime(2024, 1, 15, 12, 0),
///   source: UnavailabilitySource.manual,
///   title: 'Maintenance',
/// );
///
/// // Vérifier un chevauchement
/// final conflicts = unavailability.overlapsWith(
///   DateTime(2024, 1, 15, 10, 0),
///   DateTime(2024, 1, 15, 11, 0),
/// ); // true
/// ```
class Unavailability extends Equatable {
  final String id;

  /// ID de l'entité (studio, user, resource, etc.).
  final String entityId;

  final DateTime start;
  final DateTime end;
  final UnavailabilitySource source;

  /// ID de l'événement externe (Google Calendar, etc.).
  final String? externalEventId;

  final String? title;
  final String? description;
  final DateTime createdAt;

  /// Données additionnelles.
  final Map<String, dynamic>? metadata;

  const Unavailability({
    required this.id,
    required this.entityId,
    required this.start,
    required this.end,
    required this.source,
    this.externalEventId,
    this.title,
    this.description,
    required this.createdAt,
    this.metadata,
  });

  factory Unavailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Unavailability.fromMap(data, id: doc.id);
  }

  factory Unavailability.fromMap(Map<String, dynamic> map, {String? id}) {
    return Unavailability(
      id: id ?? map['id'] ?? '',
      entityId: map['entityId'] ?? map['studioId'] ?? '',
      start: _parseDate(map['start']),
      end: _parseDate(map['end']),
      source: UnavailabilitySource.fromString(map['source'] as String?),
      externalEventId: map['externalEventId'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      createdAt: _parseDate(map['createdAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entityId': entityId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'source': source.value,
      if (externalEventId != null) 'externalEventId': externalEventId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Vérifie si l'indisponibilité chevauche une période.
  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return start.isBefore(otherEnd) && end.isAfter(otherStart);
  }

  /// Durée en minutes.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Durée en heures.
  double get durationHours => durationMinutes / 60;

  /// Vérifie si dans le passé.
  bool get isPast => end.isBefore(DateTime.now());

  /// Vérifie si en cours.
  bool get isOngoing {
    final now = DateTime.now();
    return !start.isAfter(now) && end.isAfter(now);
  }

  Unavailability copyWith({
    String? id,
    String? entityId,
    DateTime? start,
    DateTime? end,
    UnavailabilitySource? source,
    String? externalEventId,
    String? title,
    String? description,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Unavailability(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      start: start ?? this.start,
      end: end ?? this.end,
      source: source ?? this.source,
      externalEventId: externalEventId ?? this.externalEventId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        id,
        entityId,
        start,
        end,
        source,
        externalEventId,
        title,
        createdAt,
      ];
}
