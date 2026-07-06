import 'package:equatable/equatable.dart';
import '../../models/base_message.dart';
import '../../models/base_conversation.dart';

/// États du MessagingBloc.
abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

/// État initial.
class MessagingInitialState extends MessagingState {
  const MessagingInitialState();
}

/// Chargement en cours.
class MessagingLoadingState extends MessagingState {
  const MessagingLoadingState();
}

/// Conversations chargées.
class ConversationsLoadedState extends MessagingState {
  final List<BaseConversation> conversations;
  final int totalUnreadCount;

  const ConversationsLoadedState({
    required this.conversations,
    this.totalUnreadCount = 0,
  });

  @override
  List<Object?> get props => [conversations, totalUnreadCount];
}

/// Conversation ouverte avec messages.
class ChatOpenState extends MessagingState {
  final BaseConversation conversation;
  final List<BaseMessage> messages;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isSending;

  /// Erreur transitoire du dernier envoi de message. Non-null le temps
  /// d'une émission (le bloc la clear immédiatement après) — à écouter
  /// via BlocListener pour afficher un SnackBar. Rester sur ChatOpenState
  /// (plutôt qu'émettre MessagingErrorState) préserve l'UI du chat.
  final String? sendError;

  const ChatOpenState({
    required this.conversation,
    required this.messages,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isSending = false,
    this.sendError,
  });

  ChatOpenState copyWith({
    BaseConversation? conversation,
    List<BaseMessage>? messages,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isSending,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatOpenState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isSending: isSending ?? this.isSending,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }

  @override
  List<Object?> get props => [
        conversation,
        messages,
        isLoadingMore,
        hasMoreMessages,
        isSending,
        sendError,
      ];
}

/// Erreur.
class MessagingErrorState extends MessagingState {
  final String message;

  const MessagingErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
