import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/base_conversation.dart';
import '../../models/base_message.dart';
import '../../models/smooth_response.dart';
import '../../services/base_messaging_service.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';

/// BLoC pour la gestion de la messagerie.
///
/// Gère les conversations et messages en temps réel.
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final BaseMessagingService _messagingService;

  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _conversationSubscription;

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatarUrl;
  String? _activeConversationId;
  List<BaseConversation> _conversations = []; // Cache des conversations

  /// Passe à true quand le stream conversations meurt (permission-denied
  /// au logout, blip réseau) — un stream Firestore en erreur ne ré-émet
  /// plus jamais. Le guard de _onLoadConversations laisse alors passer un
  /// rechargement pour le même userId au lieu de garder un listener mort.
  bool _conversationsStreamBroken = false;

  /// Messages reçus alors que la conversation active n'était pas encore
  /// dans le cache (ouverture par deep-link) — rejoués dès que le doc
  /// conversation arrive.
  List<BaseMessage>? _pendingMessages;

  MessagingBloc({BaseMessagingService? messagingService})
      : _messagingService = messagingService ?? BaseMessagingService(),
        super(const MessagingInitialState()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<ConversationsUpdatedEvent>(_onConversationsUpdated);
    on<OpenConversationEvent>(_onOpenConversation);
    on<MessagesUpdatedEvent>(_onMessagesUpdated);
    on<CloseConversationEvent>(_onCloseConversation);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendAttachmentMessageEvent>(_onSendAttachmentMessage);
    on<SendAudioMessageEvent>(_onSendAudioMessage);
    on<SendBusinessObjectMessageEvent>(_onSendBusinessObjectMessage);
    on<MarkConversationAsReadEvent>(_onMarkConversationAsRead);
    on<ToggleArchiveConversationEvent>(_onToggleArchive);
    on<ToggleMuteConversationEvent>(_onToggleMute);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<StartPrivateConversationEvent>(_onStartPrivateConversation);
    on<ClearMessagingEvent>(_onClear);
    on<ToggleReactionEvent>(_onToggleReaction);
  }

  /// Configure l'utilisateur courant.
  void setCurrentUser({
    required String userId,
    required String userName,
    String? avatarUrl,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserAvatarUrl = avatarUrl;
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    print('🔵 [MessagingBloc] LoadConversations for userId: ${event.userId}');
    print('🔵 [MessagingBloc] Current state: $state');
    print('🔵 [MessagingBloc] _currentUserId: $_currentUserId');

    // Si déjà en cours de chargement ou chargé pour cet utilisateur, ne rien
    // faire — SAUF si le stream est mort (erreur) : il ne ré-émettra jamais,
    // il faut le recréer.
    if (_currentUserId == event.userId && !_conversationsStreamBroken) {
      if (state is MessagingLoadingState || state is ConversationsLoadedState) {
        print('🟡 [MessagingBloc] Already loading/loaded, skipping');
        return;
      }
    }

    _currentUserId = event.userId;
    _conversationsStreamBroken = false;
    emit(const MessagingLoadingState());
    print('🔵 [MessagingBloc] Emitted MessagingLoadingState');

    await _conversationsSubscription?.cancel();
    print('🔵 [MessagingBloc] Starting stream for conversations...');

    _conversationsSubscription = _messagingService
        .streamUserConversations(event.userId)
        .listen(
          (conversations) {
            print('🟢 [MessagingBloc] Stream received ${conversations.length} conversations');
            add(ConversationsUpdatedEvent(conversations: conversations));
          },
          onError: (e) {
            print('🔴 [MessagingBloc] Stream error: $e');
            _conversationsStreamBroken = true;
            add(const ConversationsUpdatedEvent(conversations: []));
          },
        );

    // Timeout: si pas de réponse après 5 secondes, afficher liste vide
    Future.delayed(const Duration(seconds: 5), () {
      if (state is MessagingLoadingState) {
        print('🟠 [MessagingBloc] Timeout - no response after 5s, showing empty list');
        add(const ConversationsUpdatedEvent(conversations: []));
      }
    });
  }

  void _onConversationsUpdated(
    ConversationsUpdatedEvent event,
    Emitter<MessagingState> emit,
  ) {
    // Stocker les conversations en cache
    _conversations = event.conversations;

    // Si on est dans un chat, ne pas changer l'état (juste mettre à jour le cache)
    if (_activeConversationId != null && state is ChatOpenState) {
      return;
    }

    int totalUnread = 0;
    if (_currentUserId != null) {
      for (final conv in event.conversations) {
        totalUnread += conv.getUnreadCount(_currentUserId!);
      }
    }

    emit(ConversationsLoadedState(
      conversations: event.conversations,
      totalUnreadCount: totalUnread,
    ));
  }

  /// Récupère la conversation depuis le cache
  BaseConversation? _getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onOpenConversation(
    OpenConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    _activeConversationId = event.conversationId;

    await _messagesSubscription?.cancel();
    await _conversationSubscription?.cancel();

    // Écouter les mises à jour de la conversation (pour les changements en temps réel)
    _conversationSubscription = _messagingService
        .streamConversation(event.conversationId)
        .listen((conversation) {
      if (conversation != null) {
        // Mettre à jour la conversation dans le cache
        final index = _conversations.indexWhere((c) => c.id == conversation.id);
        if (index >= 0) {
          _conversations[index] = conversation;
        } else {
          _conversations.add(conversation);
        }
        // Des messages sont arrivés avant le doc conversation (deep-link) :
        // rejouer l'event maintenant que le cache est rempli.
        if (_pendingMessages != null &&
            conversation.id == _activeConversationId) {
          final pending = _pendingMessages!;
          _pendingMessages = null;
          add(MessagesUpdatedEvent(messages: pending));
        }
      }
    }, onError: (e) {
      // Sans onError, une erreur du stream (permission-denied sur logout
      // forcé pendant qu'un chat est ouvert) remonte en erreur de zone
      // non gérée → enregistrée fatal par Crashlytics. Le listener
      // messages a son propre onError ; ici le cache reste simplement figé.
      print('🔴 [MessagingBloc] Conversation stream error: $e');
    });

    // Écouter les messages
    _messagesSubscription = _messagingService
        .streamMessages(event.conversationId)
        .listen(
          (messages) => add(MessagesUpdatedEvent(messages: messages)),
          onError: (e) => add(MessagesUpdatedEvent(messages: const [])),
        );

    // Marquer comme lu
    if (_currentUserId != null) {
      add(MarkConversationAsReadEvent(conversationId: event.conversationId));
    }
  }

  void _onMessagesUpdated(
    MessagesUpdatedEvent event,
    Emitter<MessagingState> emit,
  ) {
    if (_activeConversationId == null) return;

    // Récupérer la conversation depuis le cache
    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) {
      // Conversation pas encore dans le cache (chat ouvert par deep-link /
      // notification avant que la liste des conversations ait chargé) :
      // mémoriser les messages — le listener streamConversation rejouera
      // l'event dès que le doc arrive, sinon l'écran restait blanc.
      _pendingMessages = event.messages;
      return;
    }
    _pendingMessages = null;

    // Préserver l'état isSending du state précédent
    final currentState = state;
    final isSending = currentState is ChatOpenState ? currentState.isSending : false;

    emit(ChatOpenState(
      conversation: conversation,
      messages: event.messages,
      isSending: isSending,
    ));
  }

  Future<void> _onCloseConversation(
    CloseConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    await _messagesSubscription?.cancel();
    await _conversationSubscription?.cancel();
    _activeConversationId = null;
    _pendingMessages = null;

    // Retourner à la liste des conversations
    if (_conversations.isNotEmpty) {
      int totalUnread = 0;
      if (_currentUserId != null) {
        for (final conv in _conversations) {
          totalUnread += conv.getUnreadCount(_currentUserId!);
        }
      }
      emit(ConversationsLoadedState(
        conversations: _conversations,
        totalUnreadCount: totalUnread,
      ));
    } else if (_currentUserId != null) {
      add(LoadConversationsEvent(userId: _currentUserId!));
    }
  }

  /// Clôture commune des 4 envois : remet isSending à false dans TOUS les
  /// cas (sinon la zone de saisie reste désactivée à vie — le stream
  /// _onMessagesUpdated préserve isSending) et surface l'échec via un
  /// sendError transitoire (émis puis aussitôt cleared, à écouter en
  /// BlocListener côté app pour un SnackBar).
  void _finishSend(Emitter<MessagingState> emit, SmoothResponse response) {
    final afterState = state;
    if (afterState is! ChatOpenState) return;
    if (response.isSuccess) {
      emit(afterState.copyWith(isSending: false, clearSendError: true));
    } else {
      emit(afterState.copyWith(isSending: false, sendError: response.message));
      emit((state as ChatOpenState).copyWith(clearSendError: true));
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null || _currentUserId == null) return;

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) return;

    final currentState = state;
    if (currentState is ChatOpenState) {
      emit(currentState.copyWith(isSending: true));
    }

    final response = await _messagingService.sendTextMessage(
      conversationId: conversation.id,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'Utilisateur',
      senderAvatarUrl: _currentUserAvatarUrl,
      text: event.text,
      participantIds: conversation.participantIds,
    );
    _finishSend(emit, response);
  }

  Future<void> _onSendAttachmentMessage(
    SendAttachmentMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null || _currentUserId == null) return;

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) return;

    final response = await _messagingService.sendAttachmentMessage(
      conversationId: conversation.id,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'Utilisateur',
      senderAvatarUrl: _currentUserAvatarUrl,
      caption: event.caption,
      attachment: event.attachment,
      participantIds: conversation.participantIds,
    );
    _finishSend(emit, response);
  }

  Future<void> _onSendAudioMessage(
    SendAudioMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null || _currentUserId == null) return;

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) return;

    final response = await _messagingService.sendAudioMessage(
      conversationId: conversation.id,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'Utilisateur',
      senderAvatarUrl: _currentUserAvatarUrl,
      audio: event.audio,
      participantIds: conversation.participantIds,
    );
    _finishSend(emit, response);
  }

  Future<void> _onSendBusinessObjectMessage(
    SendBusinessObjectMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null || _currentUserId == null) return;

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) return;

    final response = await _messagingService.sendBusinessObjectMessage(
      conversationId: conversation.id,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'Utilisateur',
      senderAvatarUrl: _currentUserAvatarUrl,
      businessObject: event.businessObject,
      participantIds: conversation.participantIds,
    );
    _finishSend(emit, response);
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsReadEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_currentUserId == null) return;

    await _messagingService.markConversationAsRead(
      conversationId: event.conversationId,
      userId: _currentUserId!,
    );
  }

  Future<void> _onToggleArchive(
    ToggleArchiveConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_currentUserId == null) return;

    await _messagingService.setConversationArchived(
      conversationId: event.conversationId,
      userId: _currentUserId!,
      archived: event.archived,
    );
  }

  Future<void> _onToggleMute(
    ToggleMuteConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_currentUserId == null) return;

    await _messagingService.setConversationMuted(
      conversationId: event.conversationId,
      userId: _currentUserId!,
      muted: event.muted,
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null) return;

    await _messagingService.deleteMessage(
      conversationId: _activeConversationId!,
      messageId: event.messageId,
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatOpenState) return;
    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;
    if (currentState.messages.isEmpty) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final oldestMessage = currentState.messages.first;
    final olderMessages = await _messagingService.loadOlderMessages(
      conversationId: currentState.conversation.id,
      before: oldestMessage.sentAt,
    );

    emit(currentState.copyWith(
      messages: [...olderMessages, ...currentState.messages],
      isLoadingMore: false,
      hasMoreMessages: olderMessages.length >= 30,
    ));
  }

  Future<void> _onStartPrivateConversation(
    StartPrivateConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_currentUserId == null) return;

    emit(const MessagingLoadingState());

    final result = await _messagingService.getOrCreatePrivateConversation(
      userId1: _currentUserId!,
      userId2: event.otherUserId,
      user1Info: event.currentUserInfo,
      user2Info: event.otherUserInfo,
    );

    if (result.isSuccess && result.data != null) {
      add(OpenConversationEvent(conversationId: result.data!.id));
    } else {
      emit(MessagingErrorState(message: result.message));
    }
  }

  void _onClear(
    ClearMessagingEvent event,
    Emitter<MessagingState> emit,
  ) {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    _currentUserId = null;
    _currentUserName = null;
    _currentUserAvatarUrl = null;
    _activeConversationId = null;
    _conversations = [];
    _conversationsStreamBroken = false;
    _pendingMessages = null;
    emit(const MessagingInitialState());
  }

  Future<void> _onToggleReaction(
    ToggleReactionEvent event,
    Emitter<MessagingState> emit,
  ) async {
    if (_activeConversationId == null || _currentUserId == null) return;

    await _messagingService.toggleReaction(
      conversationId: _activeConversationId!,
      messageId: event.messageId,
      userId: _currentUserId!,
      emoji: event.emoji,
    );
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    return super.close();
  }
}
