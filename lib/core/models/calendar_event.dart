import 'package:equatable/equatable.dart';

/// Type d'import pour un événement calendrier.
enum CalendarImportType {
  session('session'),
  unavailability('unavailability'),
  skip('skip');

  final String value;
  const CalendarImportType(this.value);

  static CalendarImportType fromString(String? value) {
    return CalendarImportType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarImportType.skip,
    );
  }
}

/// Événement de calendrier externe (Google, Apple, etc.).
///
/// Usage:
/// ```dart
/// final event = ExternalCalendarEvent(
///   id: 'google_evt_123',
///   title: 'Meeting',
///   start: DateTime(2024, 1, 15, 10, 0),
///   end: DateTime(2024, 1, 15, 11, 0),
///   provider: 'google',
/// );
///
/// // Pour import
/// event.copyWith(importType: CalendarImportType.session);
/// ```
class ExternalCalendarEvent extends Equatable {
  final String id;
  final String? title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final bool isAllDay;
  final String provider;

  /// Type d'import choisi par l'utilisateur.
  final CalendarImportType importType;

  /// ID du calendrier source.
  final String? calendarId;

  /// Couleur de l'événement (hex).
  final String? color;

  /// Métadonnées additionnelles.
  final Map<String, dynamic>? metadata;

  const ExternalCalendarEvent({
    required this.id,
    this.title,
    this.description,
    required this.start,
    required this.end,
    this.location,
    this.isAllDay = false,
    this.provider = 'google',
    this.importType = CalendarImportType.skip,
    this.calendarId,
    this.color,
    this.metadata,
  });

  /// Durée en minutes.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Durée en heures.
  double get durationHours => durationMinutes / 60;

  /// Vérifie si l'événement est dans le passé.
  bool get isPast => end.isBefore(DateTime.now());

  /// Vérifie si l'événement est en cours.
  bool get isOngoing {
    final now = DateTime.now();
    return !start.isAfter(now) && end.isAfter(now);
  }

  factory ExternalCalendarEvent.fromJson(Map<String, dynamic> json) {
    return ExternalCalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['summary'] as String?,
      description: json['description'] as String?,
      start: _parseDateTime(json['start']) ?? DateTime.now(),
      end: _parseDateTime(json['end']) ?? DateTime.now(),
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'google',
      importType: CalendarImportType.fromString(json['importType'] as String?),
      calendarId: json['calendarId'] as String?,
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        if (location != null) 'location': location,
        'isAllDay': isAllDay,
        'provider': provider,
        'importType': importType.value,
        if (calendarId != null) 'calendarId': calendarId,
        if (color != null) 'color': color,
        if (metadata != null) 'metadata': metadata,
      };

  /// Format pour l'API d'import.
  Map<String, dynamic> toImportJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'importType': importType.value,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      };

  ExternalCalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
    bool? isAllDay,
    String? provider,
    CalendarImportType? importType,
    String? calendarId,
    String? color,
    Map<String, dynamic>? metadata,
  }) {
    return ExternalCalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      provider: provider ?? this.provider,
      importType: importType ?? this.importType,
      calendarId: calendarId ?? this.calendarId,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      // Format Google Calendar API
      final dateTime = value['dateTime'] as String?;
      final date = value['date'] as String?;
      return DateTime.tryParse(dateTime ?? date ?? '');
    }
    return null;
  }

  @override
  List<Object?> get props => [id, title, start, end, provider, importType];
}
