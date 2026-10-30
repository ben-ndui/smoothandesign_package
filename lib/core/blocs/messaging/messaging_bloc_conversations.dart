part of 'messaging_bloc.dart';

/// Handlers de la liste des conversations : chargement, cache, archivage,
/// mute, démarrage d'une conversation privée, reset.
extension MessagingBlocConversations on MessagingBloc {
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
}
