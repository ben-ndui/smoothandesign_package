import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/smooth_firebase.dart';
import '../models/base_message.dart';
import '../models/base_conversation.dart';
import '../models/smooth_response.dart';

/// Service de messagerie temps réel avec Firestore.
///
/// Gère les conversations et messages avec support pour:
/// - Conversations privées (1:1) et groupes
/// - Messages texte, pièces jointes, objets métier
/// - Compteurs de non-lus par utilisateur
/// - Archivage par utilisateur
class BaseMessagingService {
  final String conversationsCollection;
  final String messagesSubcollection;

  BaseMessagingService({
    this.conversationsCollection = 'conversations',
    this.messagesSubcollection = 'messages',
  });

  CollectionReference<Map<String, dynamic>> get _conversations =>
      SmoothFirebase.collection(conversationsCollection);

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection(messagesSubcollection);

  // ===== STREAMS =====

  /// Stream des conversations d'un utilisateur (non archivées).
  Stream<List<BaseConversation>> streamUserConversations(String userId) {
    print('🔵 [MessagingService] streamUserConversations for userId: $userId');
    print('🔵 [MessagingService] Collection: $conversationsCollection');

    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('🟢 [MessagingService] Snapshot received: ${snapshot.docs.length} docs');
          for (var doc in snapshot.docs) {
            print('🟢 [MessagingService] Doc: ${doc.id} - ${doc.data()}');
          }
          return snapshot.docs
              .map((doc) => BaseConversation.fromMap(doc.data(), doc.id))
              .where((c) => !c.isArchivedFor(userId))
              .toList();
        });
  }

  /// Stream des conversations archivées.
  Stream<List<BaseConversation>> streamArchivedConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BaseConversation.fromMap(doc.data(), doc.id))
            .where((c) => c.isArchivedFor(userId))
            .toList());
  }

  /// Stream d'une conversation.
  Stream<BaseConversation?> streamConversation(String conversationId) {
    return _conversations.doc(conversationId).snapshots().map((doc) =>
        doc.exists ? BaseConversation.fromMap(doc.data()!, doc.id) : null);
  }

  /// Stream des messages d'une conversation.
  Stream<List<BaseMessage>> streamMessages(String conversationId,
      {int limit = 50}) {
    return _messages(conversationId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BaseMessage.fromMap(doc.data(), doc.id))
            .toList()
            .reversed
            .toList());
  }

  /// Stream du total des non-lus pour un utilisateur.
  Stream<int> streamTotalUnreadCount(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final conversation = BaseConversation.fromMap(doc.data(), doc.id);
        if (!conversation.isArchivedFor(userId)) {
          total += conversation.getUnreadCount(userId);
        }
      }
      return total;
    });
  }

  // ===== CONVERSATIONS =====

  /// Trouve ou crée une conversation privée.
  Future<SmoothResponse<BaseConversation>> getOrCreatePrivateConversation({
    required String userId1,
    required String userId2,
    required ParticipantInfo user1Info,
    required ParticipantInfo user2Info,
  }) async {
    try {
      // Chercher une conversation existante
      final existing = await _findExistingPrivateConversation(userId1, userId2);
      if (existing != null) {
        return SmoothResponse.success(data: existing);
      }

      // Créer une nouvelle conversation
      final now = DateTime.now();
      final data = {
        'type': ConversationType.private.name,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdByUserId': userId1,
        'participantIds': [userId1, userId2],
        'participantDetails': {
          userId1: user1Info.toMap(),
          userId2: user2Info.toMap(),
        },
        'unreadCounts': {userId1: 0, userId2: 0},
        'isArchived': {userId1: false, userId2: false},
      };

      final docRef = await _conversations.add(data);
      final doc = await docRef.get();

      return SmoothResponse.success(
        data: BaseConversation.fromMap(doc.data()!, doc.id),
      );
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur création conversation: $e');
    }
  }

  Future<BaseConversation?> _findExistingPrivateConversation(
      String userId1, String userId2) async {
    final query = await _conversations
        .where('type', isEqualTo: ConversationType.private.name)
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in query.docs) {
      final participants = List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(userId2) && participants.length == 2) {
        return BaseConversation.fromMap(doc.data(), doc.id);
      }
    }
    return null;
  }

  /// Archive/désarchive une conversation pour un utilisateur.
  Future<SmoothResponse<void>> setConversationArchived({
    required String conversationId,
    required String userId,
    required bool archived,
  }) async {
    try {
      await _conversations.doc(conversationId).update({
        'isArchived.$userId': archived,
      });
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur archivage: $e');
    }
  }

  /// Mute/unmute les notifications d'une conversation pour un utilisateur.
  Future<SmoothResponse<void>> setConversationMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    try {
      await _conversations.doc(conversationId).update({
        'isMuted.$userId': muted,
      });
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur mute: $e');
    }
  }

  /// Met à jour le nom d'une conversation de groupe.
  Future<SmoothResponse<void>> updateConversationName({
    required String conversationId,
    required String name,
  }) async {
    try {
      await _conversations.doc(conversationId).update({'name': name});
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur mise à jour: $e');
    }
  }

  // ===== MESSAGES =====

  /// Envoie un message texte.
  Future<SmoothResponse<BaseMessage>> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String text,
    required List<String> participantIds,
  }) async {
    try {
      final now = DateTime.now();
      final batch = SmoothFirebase.firestore.batch();

      // Créer le message
      final messageRef = _messages(conversationId).doc();
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        'text': text,
        'type': MessageType.text.name,
        'sentAt': now.toIso8601String(),
        'readBy': {senderId: now.toIso8601String()},
        'isDeleted': false,
        'status': MessageStatus.sent.name,
      };
      batch.set(messageRef, messageData);

      // Mettre à jour la conversation
      final updates = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
        'lastMessage': {
          'text': text,
          'senderId': senderId,
          'senderName': senderName,
          'sentAt': now.toIso8601String(),
          'type': MessageType.text.name,
        },
      };

      // Incrémenter les compteurs des autres participants
      for (final participantId in participantIds) {
        if (participantId != senderId) {
          updates['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      batch.update(_conversations.doc(conversationId), updates);

      await batch.commit();

      return SmoothResponse.success(
        data: BaseMessage.fromMap(messageData, messageRef.id),
      );
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur envoi message: $e');
    }
  }

  /// Envoie un message avec pièce jointe.
  Future<SmoothResponse<BaseMessage>> sendAttachmentMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? caption,
    required MessageAttachment attachment,
    required List<String> participantIds,
  }) async {
    try {
      final now = DateTime.now();
      final batch = SmoothFirebase.firestore.batch();

      final messageRef = _messages(conversationId).doc();
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        if (caption != null) 'text': caption,
        'type': MessageType.attachment.name,
        'sentAt': now.toIso8601String(),
        'readBy': {senderId: now.toIso8601String()},
        'attachment': attachment.toMap(),
        'isDeleted': false,
        'status': MessageStatus.sent.name,
      };
      batch.set(messageRef, messageData);

      final previewText = attachment.isImage ? '📷 Photo' : '📎 ${attachment.fileName}';
      final updates = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
        'lastMessage': {
          'text': previewText,
          'senderId': senderId,
          'senderName': senderName,
          'sentAt': now.toIso8601String(),
          'type': MessageType.attachment.name,
        },
      };

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          updates['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      batch.update(_conversations.doc(conversationId), updates);
      await batch.commit();

      return SmoothResponse.success(
        data: BaseMessage.fromMap(messageData, messageRef.id),
      );
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur envoi pièce jointe: $e');
    }
  }

  /// Envoie un message avec objet métier.
  Future<SmoothResponse<BaseMessage>> sendBusinessObjectMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required BusinessObjectAttachment businessObject,
    required List<String> participantIds,
  }) async {
    try {
      final now = DateTime.now();
      final batch = SmoothFirebase.firestore.batch();

      final messageRef = _messages(conversationId).doc();
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        'type': MessageType.businessObject.name,
        'sentAt': now.toIso8601String(),
        'readBy': {senderId: now.toIso8601String()},
        'businessObject': businessObject.toMap(),
        'isDeleted': false,
        'status': MessageStatus.sent.name,
      };
      batch.set(messageRef, messageData);

      final updates = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
        'lastMessage': {
          'text': '📄 ${businessObject.title}',
          'senderId': senderId,
          'senderName': senderName,
          'sentAt': now.toIso8601String(),
          'type': MessageType.businessObject.name,
        },
      };

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          updates['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      batch.update(_conversations.doc(conversationId), updates);
      await batch.commit();

      return SmoothResponse.success(
        data: BaseMessage.fromMap(messageData, messageRef.id),
      );
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur envoi objet: $e');
    }
  }

  /// Envoie un message audio.
  Future<SmoothResponse<BaseMessage>> sendAudioMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required AudioAttachment audio,
    required List<String> participantIds,
  }) async {
    try {
      final now = DateTime.now();
      final batch = SmoothFirebase.firestore.batch();

      final messageRef = _messages(conversationId).doc();
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        'type': MessageType.audio.name,
        'sentAt': now.toIso8601String(),
        'readBy': {senderId: now.toIso8601String()},
        'audio': audio.toMap(),
        'isDeleted': false,
        'status': MessageStatus.sent.name,
      };
      batch.set(messageRef, messageData);

      final updates = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
        'lastMessage': {
          'text': '🎤 ${audio.formattedDuration}',
          'senderId': senderId,
          'senderName': senderName,
          'sentAt': now.toIso8601String(),
          'type': MessageType.audio.name,
        },
      };

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          updates['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      batch.update(_conversations.doc(conversationId), updates);
      await batch.commit();

      return SmoothResponse.success(
        data: BaseMessage.fromMap(messageData, messageRef.id),
      );
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur envoi audio: $e');
    }
  }

  /// Marque la conversation comme lue pour un utilisateur.
  /// Met également à jour le champ readBy de tous les messages non lus.
  Future<SmoothResponse<void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();

      // Mettre à jour le compteur de non-lus
      await _conversations.doc(conversationId).update({
        'unreadCounts.$userId': 0,
      });

      // Marquer les messages comme lus
      await markMessagesAsRead(
        conversationId: conversationId,
        userId: userId,
        readAt: now,
      );

      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur marquage lu: $e');
    }
  }

  /// Marque les messages non lus comme lus pour un utilisateur.
  /// Met à jour le champ readBy des messages qui n'ont pas encore été lus.
  Future<SmoothResponse<void>> markMessagesAsRead({
    required String conversationId,
    required String userId,
    DateTime? readAt,
  }) async {
    try {
      final now = readAt ?? DateTime.now();

      // Récupérer les messages non lus par cet utilisateur
      final messagesQuery = await _messages(conversationId)
          .orderBy('sentAt', descending: true)
          .limit(50) // Limiter pour éviter trop de writes
          .get();

      final batch = SmoothFirebase.firestore.batch();
      int updatedCount = 0;

      for (final doc in messagesQuery.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final readBy = Map<String, dynamic>.from(data['readBy'] ?? {});

        // Ne pas marquer si c'est notre propre message ou déjà lu
        if (senderId != userId && !readBy.containsKey(userId)) {
          batch.update(doc.reference, {
            'readBy.$userId': now.toIso8601String(),
          });
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }

      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur marquage messages lus: $e');
    }
  }

  /// Supprime un message (soft delete).
  Future<SmoothResponse<void>> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _messages(conversationId).doc(messageId).update({
        'isDeleted': true,
      });
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur suppression: $e');
    }
  }

  /// Charge les anciens messages (pagination).
  Future<List<BaseMessage>> loadOlderMessages({
    required String conversationId,
    required DateTime before,
    int limit = 30,
  }) async {
    final query = await _messages(conversationId)
        .where('sentAt', isLessThan: before.toIso8601String())
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => BaseMessage.fromMap(doc.data(), doc.id))
        .toList()
        .reversed
        .toList();
  }

  // ===== REACTIONS =====

  /// Toggle une réaction sur un message.
  Future<SmoothResponse<void>> toggleReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageRef = _messages(conversationId).doc(messageId);
      final doc = await messageRef.get();

      if (!doc.exists) {
        return SmoothResponse.error(message: 'Message non trouvé');
      }

      final data = doc.data()!;
      final reactions = Map<String, List<dynamic>>.from(
        (data['reactions'] as Map<String, dynamic>?) ?? {},
      );

      final userIds = List<String>.from(reactions[emoji] ?? []);

      if (userIds.contains(userId)) {
        userIds.remove(userId);
        if (userIds.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = userIds;
        }
      } else {
        userIds.add(userId);
        reactions[emoji] = userIds;
      }

      await messageRef.update({'reactions': reactions});
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur réaction: $e');
    }
  }

  /// Ajoute une réaction à un message.
  Future<SmoothResponse<void>> addReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _messages(conversationId).doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayUnion([userId]),
      });
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur ajout réaction: $e');
    }
  }

  /// Retire une réaction d'un message.
  Future<SmoothResponse<void>> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _messages(conversationId).doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayRemove([userId]),
      });
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Erreur retrait réaction: $e');
    }
  }
}
