import '../models/time_slot.dart';
import '../models/unavailability.dart';
import '../models/working_hours.dart';

/// Interface pour un événement bloquant un créneau.
abstract class BlockingEvent {
  DateTime get start;
  DateTime get end;
}

/// Service générique pour calculer les disponibilités.
///
/// Utilise des callbacks pour récupérer les événements et indisponibilités,
/// permettant une intégration flexible avec n'importe quel backend.
///
/// Usage:
/// ```dart
/// final service = BaseAvailabilityService(
///   fetchBlockingEvents: (entityId, date) async {
///     return mySessionService.getSessionsForDate(entityId, date);
///   },
///   fetchUnavailabilities: (entityId, date) async {
///     return myUnavailabilityService.getByDate(entityId, date);
///   },
/// );
///
/// // Récupérer les créneaux
/// final slots = await service.getAvailableSlots(
///   entityId: 'studio123',
///   date: DateTime.now(),
///   workingHours: WorkingHours.defaultSchedule(),
/// );
/// ```
class BaseAvailabilityService {
  /// Callback pour récupérer les événements bloquants (sessions, réservations).
  final Future<List<BlockingEvent>> Function(String entityId, DateTime date)?
      fetchBlockingEvents;

  /// Callback pour récupérer les indisponibilités.
  final Future<List<Unavailability>> Function(String entityId, DateTime date)?
      fetchUnavailabilities;

  // Configuration par défaut
  static const int defaultOpeningHour = 9;
  static const int defaultClosingHour = 18;
  static const int defaultSlotDurationMinutes = 60;

  BaseAvailabilityService({
    this.fetchBlockingEvents,
    this.fetchUnavailabilities,
  });

  /// Récupère les créneaux disponibles pour un jour donné.
  Future<List<TimeSlot>> getAvailableSlots({
    required String entityId,
    required DateTime date,
    int slotDurationMinutes = defaultSlotDurationMinutes,
    int openingHour = defaultOpeningHour,
    int closingHour = defaultClosingHour,
    WorkingHours? workingHours,
  }) async {
    // Vérifier les horaires de travail
    if (workingHours != null) {
      final daySchedule = workingHours.getScheduleForDay(date.weekday);
      if (!daySchedule.enabled) {
        return []; // Fermé ce jour
      }
      final (startH, startM) = daySchedule.startTime;
      final (endH, _) = daySchedule.endTime;
      openingHour = startH + (startM > 0 ? 1 : 0);
      closingHour = endH;
    }

    // Récupérer les événements bloquants
    List<BlockingEvent> blockingEvents = [];
    if (fetchBlockingEvents != null) {
      blockingEvents = await fetchBlockingEvents!(entityId, date);
    }

    // Récupérer les indisponibilités
    List<Unavailability> unavailabilities = [];
    if (fetchUnavailabilities != null) {
      unavailabilities = await fetchUnavailabilities!(entityId, date);
    }

    // Calculer les créneaux
    return _calculateSlots(
      date: date,
      blockingEvents: blockingEvents,
      unavailabilities: unavailabilities,
      slotDurationMinutes: slotDurationMinutes,
      openingHour: openingHour,
      closingHour: closingHour,
    );
  }

  /// Génère les créneaux pour une date sans vérification de disponibilité.
  List<TimeSlot> generateSlots({
    required DateTime date,
    int slotDurationMinutes = defaultSlotDurationMinutes,
    int openingHour = defaultOpeningHour,
    int closingHour = defaultClosingHour,
    WorkingHours? workingHours,
  }) {
    if (workingHours != null) {
      final daySchedule = workingHours.getScheduleForDay(date.weekday);
      if (!daySchedule.enabled) return [];
      final (startH, startM) = daySchedule.startTime;
      final (endH, _) = daySchedule.endTime;
      openingHour = startH + (startM > 0 ? 1 : 0);
      closingHour = endH;
    }

    final slots = <TimeSlot>[];
    final slotDuration = Duration(minutes: slotDurationMinutes);

    var currentTime = DateTime(date.year, date.month, date.day, openingHour);
    final closingTime = DateTime(date.year, date.month, date.day, closingHour);

    while (currentTime.add(slotDuration).isBefore(closingTime) ||
        currentTime.add(slotDuration).isAtSameMomentAs(closingTime)) {
      final slotEnd = currentTime.add(slotDuration);
      slots.add(TimeSlot(start: currentTime, end: slotEnd, isAvailable: true));
      currentTime = slotEnd;
    }

    return slots;
  }

  /// Vérifie si un créneau spécifique est disponible.
  Future<bool> isSlotAvailable({
    required String entityId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Vérifier les événements bloquants
    if (fetchBlockingEvents != null) {
      final events = await fetchBlockingEvents!(entityId, start);
      for (final event in events) {
        if (_overlaps(start, end, event.start, event.end)) {
          return false;
        }
      }
    }

    // Vérifier les indisponibilités
    if (fetchUnavailabilities != null) {
      final unavailabilities = await fetchUnavailabilities!(entityId, start);
      for (final u in unavailabilities) {
        if (u.overlapsWith(start, end)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Calcule les créneaux avec leur disponibilité.
  List<TimeSlot> _calculateSlots({
    required DateTime date,
    required List<BlockingEvent> blockingEvents,
    required List<Unavailability> unavailabilities,
    required int slotDurationMinutes,
    required int openingHour,
    required int closingHour,
  }) {
    final slots = <TimeSlot>[];
    final slotDuration = Duration(minutes: slotDurationMinutes);

    var currentTime = DateTime(date.year, date.month, date.day, openingHour);
    final closingTime = DateTime(date.year, date.month, date.day, closingHour);

    while (currentTime.add(slotDuration).isBefore(closingTime) ||
        currentTime.add(slotDuration).isAtSameMomentAs(closingTime)) {
      final slotEnd = currentTime.add(slotDuration);

      final isAvailable = _isSlotAvailable(
        currentTime,
        slotEnd,
        blockingEvents,
        unavailabilities,
      );

      slots.add(TimeSlot(
        start: currentTime,
        end: slotEnd,
        isAvailable: isAvailable,
      ));

      currentTime = slotEnd;
    }

    return slots;
  }

  bool _isSlotAvailable(
    DateTime start,
    DateTime end,
    List<BlockingEvent> blockingEvents,
    List<Unavailability> unavailabilities,
  ) {
    // Vérifier les événements bloquants
    for (final event in blockingEvents) {
      if (_overlaps(start, end, event.start, event.end)) {
        return false;
      }
    }

    // Vérifier les indisponibilités
    for (final u in unavailabilities) {
      if (u.overlapsWith(start, end)) {
        return false;
      }
    }

    return true;
  }

  bool _overlaps(DateTime s1, DateTime e1, DateTime s2, DateTime e2) {
    return s1.isBefore(e2) && e1.isAfter(s2);
  }
}
