import 'package:equatable/equatable.dart';
import '../../models/base_message.dart';
import '../../models/base_conversation.dart';

/// Events du MessagingBloc.
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les conversations d'un utilisateur.
class LoadConversationsEvent extends MessagingEvent {
  final String userId;

  const LoadConversationsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Mise à jour des conversations (interne).
class ConversationsUpdatedEvent extends MessagingEvent {
  final List<BaseConversation> conversations;

  const ConversationsUpdatedEvent({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

/// Ouvre une conversation pour charger les messages.
class OpenConversationEvent extends MessagingEvent {
  final String conversationId;

  const OpenConversationEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

/// Mise à jour des messages (interne).
class MessagesUpdatedEvent extends MessagingEvent {
  final List<BaseMessage> messages;

  const MessagesUpdatedEvent({required this.messages});

  @override
  List<Object?> get props => [messages];
}

/// Ferme la conversation active.
class CloseConversationEvent extends MessagingEvent {
  const CloseConversationEvent();
}

/// Envoie un message texte.
class SendTextMessageEvent extends MessagingEvent {
  final String text;

  const SendTextMessageEvent({required this.text});

  @override
  List<Object?> get props => [text];
}

/// Envoie une pièce jointe.
class SendAttachmentMessageEvent extends MessagingEvent {
  final MessageAttachment attachment;
  final String? caption;

  const SendAttachmentMessageEvent({
    required this.attachment,
    this.caption,
  });

  @override
  List<Object?> get props => [attachment, caption];
}

/// Envoie un message audio.
class SendAudioMessageEvent extends MessagingEvent {
  final AudioAttachment audio;

  const SendAudioMessageEvent({required this.audio});

  @override
  List<Object?> get props => [audio];
}

/// Envoie un objet métier.
class SendBusinessObjectMessageEvent extends MessagingEvent {
  final BusinessObjectAttachment businessObject;

  const SendBusinessObjectMessageEvent({required this.businessObject});

  @override
  List<Object?> get props => [businessObject];
}

/// Marque la conversation comme lue.
class MarkConversationAsReadEvent extends MessagingEvent {
  final String conversationId;

  const MarkConversationAsReadEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

/// Archive/désarchive une conversation.
class ToggleArchiveConversationEvent extends MessagingEvent {
  final String conversationId;
  final bool archived;

  const ToggleArchiveConversationEvent({
    required this.conversationId,
    required this.archived,
  });

  @override
  List<Object?> get props => [conversationId, archived];
}

/// Mute/unmute les notifications d'une conversation.
class ToggleMuteConversationEvent extends MessagingEvent {
  final String conversationId;
  final bool muted;

  const ToggleMuteConversationEvent({
    required this.conversationId,
    required this.muted,
  });

  @override
  List<Object?> get props => [conversationId, muted];
}

/// Supprime un message.
class DeleteMessageEvent extends MessagingEvent {
  final String messageId;

  const DeleteMessageEvent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Charge plus de messages (pagination).
class LoadMoreMessagesEvent extends MessagingEvent {
  const LoadMoreMessagesEvent();
}

/// Démarre une nouvelle conversation privée.
class StartPrivateConversationEvent extends MessagingEvent {
  final String otherUserId;
  final ParticipantInfo otherUserInfo;
  final ParticipantInfo currentUserInfo;

  const StartPrivateConversationEvent({
    required this.otherUserId,
    required this.otherUserInfo,
    required this.currentUserInfo,
  });

  @override
  List<Object?> get props => [otherUserId, otherUserInfo, currentUserInfo];
}

/// Nettoie l'état lors de la déconnexion.
class ClearMessagingEvent extends MessagingEvent {
  const ClearMessagingEvent();
}

/// Toggle une réaction sur un message.
class ToggleReactionEvent extends MessagingEvent {
  final String messageId;
  final String emoji;

  const ToggleReactionEvent({required this.messageId, required this.emoji});

  @override
  List<Object?> get props => [messageId, emoji];
}
