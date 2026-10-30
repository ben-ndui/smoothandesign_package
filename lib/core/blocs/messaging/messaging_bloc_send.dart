part of 'messaging_bloc.dart';

/// Les 4 envois (texte, pièce jointe, audio, objet métier) et leur
/// clôture commune.
extension MessagingBlocSend on MessagingBloc {
  /// Les 4 envois gardaient le même garde-fou silencieux : conversation
  /// pas encore dans le cache local (stream pas encore arrivé) -> `return`
  /// nu, rien n'est écrit en Firestore et rien ne le dit à l'utilisateur
  /// (relevé par Ben le 30/10, message tapé puis parti nulle part). On
  /// surface désormais la même erreur transitoire que `_finishSend`.
  void _failSilentSend(Emitter<MessagingState> emit) {
    final current = state;
    if (current is! ChatOpenState) return;
    emit(current.copyWith(sendError: 'Conversation pas encore chargée, réessaie.'));
    emit((state as ChatOpenState).copyWith(clearSendError: true));
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
    if (_activeConversationId == null || _currentUserId == null) {
      _failSilentSend(emit);
      return;
    }

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) {
      _failSilentSend(emit);
      return;
    }

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
    if (_activeConversationId == null || _currentUserId == null) {
      _failSilentSend(emit);
      return;
    }

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) {
      _failSilentSend(emit);
      return;
    }

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
    if (_activeConversationId == null || _currentUserId == null) {
      _failSilentSend(emit);
      return;
    }

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) {
      _failSilentSend(emit);
      return;
    }

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
    if (_activeConversationId == null || _currentUserId == null) {
      _failSilentSend(emit);
      return;
    }

    final conversation = _getConversationById(_activeConversationId!);
    if (conversation == null) {
      _failSilentSend(emit);
      return;
    }

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
}
