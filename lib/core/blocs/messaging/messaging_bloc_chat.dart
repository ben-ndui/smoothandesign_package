part of 'messaging_bloc.dart';

/// Handlers d'un chat ouvert : stream messages/conversation, fermeture,
/// lecture, pagination, suppression, réaction.
extension MessagingBlocChat on MessagingBloc {
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
}
