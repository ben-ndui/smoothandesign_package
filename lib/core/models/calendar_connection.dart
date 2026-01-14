import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Provider de calendrier supporté.
enum CalendarProvider {
  google('google', 'Google Calendar'),
  apple('apple', 'Apple Calendar'),
  outlook('outlook', 'Outlook'),
  other('other', 'Other');

  final String value;
  final String label;

  const CalendarProvider(this.value, this.label);

  static CalendarProvider fromString(String? value) {
    return CalendarProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarProvider.other,
    );
  }
}

/// Modèle de connexion calendrier.
///
/// Usage:
/// ```dart
/// final connection = CalendarConnection(
///   provider: CalendarProvider.google,
///   connected: true,
///   email: 'user@gmail.com',
///   lastSync: DateTime.now(),
/// );
///
/// if (connection.needsResync(Duration(hours: 1))) {
///   // Resync needed
/// }
/// ```
class CalendarConnection extends Equatable {
  final CalendarProvider provider;
  final bool connected;
  final String? email;
  final String calendarId;
  final DateTime? lastSync;
  final DateTime? connectedAt;

  /// Token d'accès (à stocker de manière sécurisée).
  final String? accessToken;

  /// Token de refresh.
  final String? refreshToken;

  /// Expiration du token d'accès.
  final DateTime? tokenExpiresAt;

  /// Métadonnées additionnelles.
  final Map<String, dynamic>? metadata;

  const CalendarConnection({
    required this.provider,
    required this.connected,
    this.email,
    this.calendarId = 'primary',
    this.lastSync,
    this.connectedAt,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.metadata,
  });

  /// Vérifie si le token est expiré.
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  /// Vérifie si une resync est nécessaire.
  bool needsResync(Duration interval) {
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync!) > interval;
  }

  /// Temps depuis la dernière sync.
  Duration? get timeSinceLastSync {
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync!);
  }

  factory CalendarConnection.fromMap(Map<String, dynamic> map) {
    return CalendarConnection(
      provider: CalendarProvider.fromString(map['provider'] as String?),
      connected: map['connected'] as bool? ?? false,
      email: map['email'] as String?,
      calendarId: map['calendarId'] as String? ?? 'primary',
      lastSync: _parseDateTime(map['lastSync']),
      connectedAt: _parseDateTime(map['connectedAt']),
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      tokenExpiresAt: _parseDateTime(map['tokenExpiresAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.value,
      'connected': connected,
      if (email != null) 'email': email,
      'calendarId': calendarId,
      if (lastSync != null) 'lastSync': Timestamp.fromDate(lastSync!),
      if (connectedAt != null) 'connectedAt': Timestamp.fromDate(connectedAt!),
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (tokenExpiresAt != null)
        'tokenExpiresAt': Timestamp.fromDate(tokenExpiresAt!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  CalendarConnection copyWith({
    CalendarProvider? provider,
    bool? connected,
    String? email,
    String? calendarId,
    DateTime? lastSync,
    DateTime? connectedAt,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarConnection(
      provider: provider ?? this.provider,
      connected: connected ?? this.connected,
      email: email ?? this.email,
      calendarId: calendarId ?? this.calendarId,
      lastSync: lastSync ?? this.lastSync,
      connectedAt: connectedAt ?? this.connectedAt,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Crée une connexion déconnectée.
  factory CalendarConnection.disconnected({
    CalendarProvider provider = CalendarProvider.google,
  }) {
    return CalendarConnection(
      provider: provider,
      connected: false,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  List<Object?> get props => [
        provider,
        connected,
        email,
        calendarId,
        lastSync,
        connectedAt,
        tokenExpiresAt,
      ];
}
