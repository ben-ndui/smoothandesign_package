import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Type de message.
enum MessageType {
  text,
  attachment,
  businessObject,
  audio;

  static MessageType fromString(String? value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Statut d'envoi/lecture d'un message.
enum MessageStatus {
  /// Message en cours d'envoi (pas encore sur le serveur).
  sending,

  /// Message envoyé au serveur.
  sent,

  /// Message délivré au(x) destinataire(s) - optionnel.
  delivered,

  /// Message lu par au moins un destinataire.
  read,

  /// Échec d'envoi.
  failed;

  static MessageStatus fromString(String? value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Pièce jointe d'un message.
class MessageAttachment extends Equatable {
  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? thumbnailUrl;

  const MessageAttachment({
    required this.url,
    required this.fileName,
    required this.fileType,
    this.fileSize = 0,
    this.thumbnailUrl,
  });

  bool get isImage =>
      fileType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.gif');

  bool get isPdf =>
      fileType == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      url: map['url'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? 'application/octet-stream',
      fileSize: map['fileSize'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };

  @override
  List<Object?> get props => [url, fileName, fileType, fileSize, thumbnailUrl];
}

/// Référence à un objet métier (devis, facture, mission).
class BusinessObjectAttachment extends Equatable {
  final String objectType; // 'quote', 'invoice', 'mission'
  final String objectId;
  final String title;
  final String? status;
  final double? amount;
  final String? clientName;

  const BusinessObjectAttachment({
    required this.objectType,
    required this.objectId,
    required this.title,
    this.status,
    this.amount,
    this.clientName,
  });

  factory BusinessObjectAttachment.fromMap(Map<String, dynamic> map) {
    return BusinessObjectAttachment(
      objectType: map['objectType'] ?? map['type'] ?? '',
      objectId: map['objectId'] ?? map['id'] ?? '',
      title: map['title'] ?? '',
      status: map['status'],
      amount: (map['amount'] as num?)?.toDouble(),
      clientName: map['clientName'],
    );
  }

  Map<String, dynamic> toMap() => {
        'objectType': objectType,
        'objectId': objectId,
        'title': title,
        if (status != null) 'status': status,
        if (amount != null) 'amount': amount,
        if (clientName != null) 'clientName': clientName,
      };

  @override
  List<Object?> get props =>
      [objectType, objectId, title, status, amount, clientName];
}

/// Pièce jointe audio d'un message.
class AudioAttachment extends Equatable {
  final String url;
  final int durationSeconds;
  final String? waveformData;

  const AudioAttachment({
    required this.url,
    required this.durationSeconds,
    this.waveformData,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory AudioAttachment.fromMap(Map<String, dynamic> map) {
    return AudioAttachment(
      url: map['url'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      waveformData: map['waveformData'],
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'durationSeconds': durationSeconds,
        if (waveformData != null) 'waveformData': waveformData,
      };

  @override
  List<Object?> get props => [url, durationSeconds, waveformData];
}

/// Message de chat.
class BaseMessage extends Equatable {
  /// Parse une date depuis Firestore (Timestamp ou String).
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? text;
  final MessageType type;
  final DateTime sentAt;
  final Map<String, DateTime> readBy;
  final MessageAttachment? attachment;
  final BusinessObjectAttachment? businessObject;
  final AudioAttachment? audio;
  final bool isDeleted;
  final DateTime? editedAt;
  final Map<String, List<String>> reactions; // emoji → [userId1, userId2, ...]
  final MessageStatus status;

  const BaseMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    this.text,
    this.type = MessageType.text,
    required this.sentAt,
    this.readBy = const {},
    this.attachment,
    this.businessObject,
    this.audio,
    this.isDeleted = false,
    this.editedAt,
    this.reactions = const {},
    this.status = MessageStatus.sent,
  });

  /// Texte d'affichage pour la preview.
  String get displayText {
    if (isDeleted) return 'Message supprimé';
    if (text != null && text!.isNotEmpty) return text!;
    if (attachment != null) return '📎 ${attachment!.fileName}';
    if (businessObject != null) return '📄 ${businessObject!.title}';
    if (audio != null) return '🎤 ${audio!.formattedDuration}';
    return '';
  }

  /// Vérifie si lu par un utilisateur.
  bool isReadBy(String userId) => readBy.containsKey(userId);

  /// Calcule le statut effectif du message en fonction de readBy.
  /// Utile pour afficher les indicateurs visuels (✓ ✓✓).
  /// [otherParticipantIds] : IDs des autres participants (excluant l'expéditeur).
  MessageStatus getEffectiveStatus(List<String> otherParticipantIds) {
    if (status == MessageStatus.sending || status == MessageStatus.failed) {
      return status;
    }

    // Si au moins un autre participant a lu le message
    final hasBeenRead = otherParticipantIds.any((id) => readBy.containsKey(id));
    if (hasBeenRead) {
      return MessageStatus.read;
    }

    // Sinon, le message est juste envoyé
    return status;
  }

  /// Vérifie si le message a été lu par tous les autres participants.
  bool isReadByAll(List<String> otherParticipantIds) {
    if (otherParticipantIds.isEmpty) return false;
    return otherParticipantIds.every((id) => readBy.containsKey(id));
  }

  factory BaseMessage.fromMap(Map<String, dynamic> map, String id) {
    return BaseMessage(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatarUrl: map['senderAvatarUrl'],
      text: map['text'],
      type: MessageType.fromString(map['type']),
      sentAt: _parseDate(map['sentAt']),
      readBy: map['readBy'] is Map
          ? (map['readBy'] as Map).map(
              (k, v) => MapEntry(k.toString(), _parseDate(v)),
            )
          : {},
      attachment: map['attachment'] != null
          ? MessageAttachment.fromMap(map['attachment'])
          : null,
      businessObject: map['businessObject'] != null
          ? BusinessObjectAttachment.fromMap(map['businessObject'])
          : null,
      audio: map['audio'] != null
          ? AudioAttachment.fromMap(map['audio'])
          : null,
      isDeleted: map['isDeleted'] ?? false,
      editedAt: map['editedAt'] != null ? _parseDate(map['editedAt']) : null,
      reactions: map['reactions'] is Map
          ? (map['reactions'] as Map).map(
              (k, v) => MapEntry(
                k.toString(),
                v is List ? List<String>.from(v) : <String>[],
              ),
            )
          : {},
      status: MessageStatus.fromString(map['status']),
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        if (text != null) 'text': text,
        'type': type.name,
        'sentAt': sentAt.toIso8601String(),
        'readBy': readBy.map((k, v) => MapEntry(k, v.toIso8601String())),
        if (attachment != null) 'attachment': attachment!.toMap(),
        if (businessObject != null) 'businessObject': businessObject!.toMap(),
        if (audio != null) 'audio': audio!.toMap(),
        'isDeleted': isDeleted,
        if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
        if (reactions.isNotEmpty) 'reactions': reactions,
        'status': status.name,
      };

  BaseMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? text,
    MessageType? type,
    DateTime? sentAt,
    Map<String, DateTime>? readBy,
    MessageAttachment? attachment,
    BusinessObjectAttachment? businessObject,
    AudioAttachment? audio,
    bool? isDeleted,
    DateTime? editedAt,
    Map<String, List<String>>? reactions,
    MessageStatus? status,
  }) {
    return BaseMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      text: text ?? this.text,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
      attachment: attachment ?? this.attachment,
      businessObject: businessObject ?? this.businessObject,
      audio: audio ?? this.audio,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
    );
  }

  /// Vérifie si un utilisateur a réagi avec un emoji.
  bool hasReacted(String userId, String emoji) =>
      reactions[emoji]?.contains(userId) ?? false;

  /// Retourne tous les emojis utilisés dans les réactions.
  List<String> get reactionEmojis => reactions.keys.toList();

  /// Retourne le nombre total de réactions.
  int get totalReactions =>
      reactions.values.fold(0, (total, users) => total + users.length);

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        text,
        type,
        sentAt,
        isDeleted,
        reactions,
        status,
      ];
}
