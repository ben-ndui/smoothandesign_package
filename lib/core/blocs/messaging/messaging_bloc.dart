import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/base_conversation.dart';
import '../../models/base_message.dart';
import '../../models/smooth_response.dart';
import '../../services/base_messaging_service.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';

part 'messaging_bloc_conversations.dart';
part 'messaging_bloc_chat.dart';
part 'messaging_bloc_send.dart';

/// BLoC pour la gestion de la messagerie.
///
/// Gère les conversations et messages en temps réel. Les handlers sont
/// répartis par sujet dans des extensions `part of` (conversations/chat/
/// envoi) pour tenir sous 250 lignes par fichier — toujours une seule
/// classe, un seul état privé.
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
    on<LoadConversationsEvent>(_onLoadConversations, transformer: restartable());
    on<ConversationsUpdatedEvent>(_onConversationsUpdated);
    on<OpenConversationEvent>(_onOpenConversation, transformer: restartable());
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

  /// Récupère la conversation depuis le cache (utilisé par les 3 parts).
  BaseConversation? _getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    return super.close();
  }
}
