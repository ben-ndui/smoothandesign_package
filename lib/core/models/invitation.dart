import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status d'une invitation.
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled'),
  expired('expired');

  final String value;
  const InvitationStatus(this.value);

  static InvitationStatus fromString(String? value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

/// Modèle générique d'invitation.
///
/// Usage:
/// ```dart
/// final invitation = Invitation(
///   id: 'inv123',
///   organizationId: 'org456',
///   organizationName: 'Mon Organisation',
///   email: 'user@example.com',
///   code: 'TEAM-ABC123',
///   status: InvitationStatus.pending,
///   role: 'member',
///   expiresAt: DateTime.now().add(Duration(days: 30)),
/// );
///
/// // Vérifier validité
/// if (invitation.isPending) {
///   // Peut être acceptée
/// }
/// ```
class Invitation extends Equatable {
  final String id;

  /// ID de l'organisation/équipe/studio invitant.
  final String organizationId;

  /// Nom affiché de l'organisation.
  final String organizationName;

  /// Email de l'invité.
  final String email;

  /// Nom optionnel de l'invité.
  final String? inviteeName;

  /// Code d'invitation unique.
  final String code;

  final InvitationStatus status;

  /// Rôle attribué après acceptation.
  final String? role;

  final DateTime createdAt;
  final DateTime expiresAt;

  /// ID de l'utilisateur ayant créé l'invitation.
  final String? createdByUserId;

  /// ID de l'utilisateur ayant accepté.
  final String? acceptedByUserId;

  final DateTime? acceptedAt;
  final DateTime? declinedAt;

  /// Message personnalisé.
  final String? message;

  /// Données additionnelles.
  final Map<String, dynamic>? metadata;

  const Invitation({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.email,
    this.inviteeName,
    required this.code,
    required this.status,
    this.role,
    required this.createdAt,
    required this.expiresAt,
    this.createdByUserId,
    this.acceptedByUserId,
    this.acceptedAt,
    this.declinedAt,
    this.message,
    this.metadata,
  });

  factory Invitation.fromMap(Map<String, dynamic> map, {String? id}) {
    return Invitation(
      id: id ?? map['id'] ?? '',
      organizationId: map['organizationId'] ?? map['studioId'] ?? '',
      organizationName: map['organizationName'] ?? map['studioName'] ?? '',
      email: map['email'] ?? '',
      inviteeName: map['inviteeName'] ?? map['name'],
      code: map['code'] ?? '',
      status: InvitationStatus.fromString(map['status']),
      role: map['role'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(map['expiresAt']) ?? DateTime.now(),
      createdByUserId: map['createdByUserId'],
      acceptedByUserId: map['acceptedByUserId'],
      acceptedAt: _parseDateTime(map['acceptedAt']),
      declinedAt: _parseDateTime(map['declinedAt']),
      message: map['message'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'email': email,
        if (inviteeName != null) 'inviteeName': inviteeName,
        'code': code,
        'status': status.value,
        if (role != null) 'role': role,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
        if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
        if (acceptedAt != null)
          'acceptedAt': acceptedAt!.millisecondsSinceEpoch,
        if (declinedAt != null)
          'declinedAt': declinedAt!.millisecondsSinceEpoch,
        if (message != null) 'message': message,
        if (metadata != null) 'metadata': metadata,
      };

  /// Vérifie si l'invitation est expirée.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Vérifie si l'invitation est en attente et valide.
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  /// Vérifie si l'invitation peut être acceptée.
  bool get canBeAccepted => isPending;

  /// Jours restants avant expiration.
  int get daysUntilExpiry {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  Invitation copyWith({
    String? id,
    String? organizationId,
    String? organizationName,
    String? email,
    String? inviteeName,
    String? code,
    InvitationStatus? status,
    String? role,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? createdByUserId,
    String? acceptedByUserId,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return Invitation(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      inviteeName: inviteeName ?? this.inviteeName,
      code: code ?? this.code,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        email,
        code,
        status,
        createdAt,
        expiresAt,
      ];
}
