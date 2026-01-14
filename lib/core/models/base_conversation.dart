import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Type de conversation.
enum ConversationType {
  private,
  group;

  static ConversationType fromString(String? value) {
    return ConversationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConversationType.private,
    );
  }
}

/// Informations sur un participant.
class ParticipantInfo extends Equatable {
  final String name;
  final String? avatarUrl;
  final String? role;

  const ParticipantInfo({
    required this.name,
    this.avatarUrl,
    this.role,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (role != null) 'role': role,
      };

  @override
  List<Object?> get props => [name, avatarUrl, role];
}

/// Résumé du dernier message.
class LastMessageSummary extends Equatable {
  final String text;
  final String senderId;
  final String senderName;
  final DateTime sentAt;
  final String type;

  const LastMessageSummary({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.sentAt,
    this.type = 'text',
  });

  /// Parse une date depuis Firestore (Timestamp ou String).
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  factory LastMessageSummary.fromMap(Map<String, dynamic> map) {
    return LastMessageSummary(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      sentAt: _parseDate(map['sentAt']),
      type: map['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'sentAt': sentAt.toIso8601String(),
        'type': type,
      };

  @override
  List<Object?> get props => [text, senderId, senderName, sentAt, type];
}

/// Conversation de chat.
class BaseConversation extends Equatable {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUserId;
  final List<String> participantIds;
  final Map<String, ParticipantInfo> participantDetails;
  final Map<String, int> unreadCounts;
  final Map<String, bool> isArchived;
  final LastMessageSummary? lastMessage;

  const BaseConversation({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
    required this.participantIds,
    this.participantDetails = const {},
    this.unreadCounts = const {},
    this.isArchived = const {},
    this.lastMessage,
  });

  /// Nombre de messages non lus pour un utilisateur.
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  /// Vérifie si archivée pour un utilisateur.
  bool isArchivedFor(String userId) => isArchived[userId] ?? false;

  /// Nom d'affichage de la conversation.
  String getDisplayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) return name!;

    // Pour une conversation privée, afficher le nom de l'autre participant
    if (type == ConversationType.private) {
      final otherId = participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return participantDetails[otherId]?.name ?? 'Conversation';
    }

    // Pour un groupe, lister les noms
    final names = participantDetails.values.map((p) => p.name).take(3).toList();
    if (names.isEmpty) return 'Groupe';
    return names.join(', ');
  }

  /// Avatar de la conversation pour un utilisateur.
  String? getAvatarUrl(String currentUserId) {
    if (avatarUrl != null) return avatarUrl;

    if (type == ConversationType.private) {
      final otherId = participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return participantDetails[otherId]?.avatarUrl;
    }

    return null;
  }

  /// Parse une date depuis Firestore (Timestamp ou String).
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  factory BaseConversation.fromMap(Map<String, dynamic> map, String id) {
    // Support both 'participantDetails' and legacy 'participantInfo'
    final rawDetails = map['participantDetails'] ?? map['participantInfo'];
    Map<String, ParticipantInfo> participantDetails = {};
    if (rawDetails != null && rawDetails is Map) {
      rawDetails.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          participantDetails[k.toString()] = ParticipantInfo.fromMap(v);
        } else if (v is Map) {
          participantDetails[k.toString()] = ParticipantInfo.fromMap(Map<String, dynamic>.from(v));
        }
      });
    }

    // Support both 'isArchived' map and legacy 'archivedBy' array
    Map<String, bool> archivedMap = {};
    if (map['isArchived'] != null && map['isArchived'] is Map) {
      (map['isArchived'] as Map).forEach((k, v) {
        archivedMap[k.toString()] = v == true;
      });
    } else if (map['archivedBy'] != null && map['archivedBy'] is List) {
      for (final userId in List<String>.from(map['archivedBy'])) {
        archivedMap[userId] = true;
      }
    }

    // Parse unreadCounts safely
    Map<String, int> unreadCounts = {};
    if (map['unreadCounts'] != null && map['unreadCounts'] is Map) {
      (map['unreadCounts'] as Map).forEach((k, v) {
        unreadCounts[k.toString()] = (v is num) ? v.toInt() : 0;
      });
    }

    // Parse lastMessage safely
    LastMessageSummary? lastMessage;
    if (map['lastMessage'] != null && map['lastMessage'] is Map) {
      try {
        lastMessage = LastMessageSummary.fromMap(Map<String, dynamic>.from(map['lastMessage']));
      } catch (_) {
        lastMessage = null;
      }
    }

    return BaseConversation(
      id: id,
      type: ConversationType.fromString(map['type']?.toString()),
      name: map['name']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt'] ?? map['createdAt']),
      createdByUserId: map['createdByUserId']?.toString() ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantDetails: participantDetails,
      unreadCounts: unreadCounts,
      isArchived: archivedMap,
      lastMessage: lastMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdByUserId': createdByUserId,
        'participantIds': participantIds,
        'participantDetails':
            participantDetails.map((k, v) => MapEntry(k, v.toMap())),
        'unreadCounts': unreadCounts,
        'isArchived': isArchived,
        if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
      };

  BaseConversation copyWith({
    String? id,
    ConversationType? type,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
    List<String>? participantIds,
    Map<String, ParticipantInfo>? participantDetails,
    Map<String, int>? unreadCounts,
    Map<String, bool>? isArchived,
    LastMessageSummary? lastMessage,
  }) {
    return BaseConversation(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      participantIds: participantIds ?? this.participantIds,
      participantDetails: participantDetails ?? this.participantDetails,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isArchived: isArchived ?? this.isArchived,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        participantIds,
        updatedAt,
        lastMessage,
      ];
}
