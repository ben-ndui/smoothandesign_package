import 'package:flutter/material.dart';
import '../../models/base_message.dart';
import '../../models/base_conversation.dart';
import 'chat_messages_list.dart';
import 'message_input.dart';

/// Vue de chat complète avec messages et input.
class ChatView extends StatefulWidget {
  final BaseConversation conversation;
  final List<BaseMessage> messages;
  final String currentUserId;
  final Function(String) onSendText;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onAudioTap;
  final VoidCallback? onMicLongPressStart;
  final VoidCallback? onMicLongPressEnd;
  final bool isRecording;
  final bool showAudioPreview;
  final Widget? audioPreviewWidget;
  final Widget? recordingOverlay;
  final VoidCallback? onLoadMore;
  final Function(BaseMessage)? onMessageLongPress;
  final Function(BaseMessage)? onAttachmentTap2;
  final Function(BaseMessage)? onBusinessObjectTap;
  final Function(BaseMessage)? onAudioMessageTap;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isSending;
  final Widget? emptyWidget;

  /// Affiche le bouton pièce jointe dans la barre de saisie (défaut: true).
  /// Mettre à `false` pour un chat texte seul (callbacks non câblés).
  final bool showAttachmentButton;

  /// Affiche le bouton audio/micro dans la barre de saisie (défaut: true).
  final bool showAudioButton;

  /// Builder personnalisé pour les business objects (session, booking, etc.).
  final Widget Function(BusinessObjectAttachment bo, bool isMe)? businessObjectBuilder;

  /// Builder pour afficher les réactions sous les messages.
  final Widget Function(Map<String, List<String>> reactions, String? currentUserId)? reactionBuilder;

  /// Callback quand un utilisateur tape sur une réaction.
  final void Function(BaseMessage message, String emoji)? onReactionTap;

  /// Transmis tel quel à [MessageInput.floating] (défaut `false`).
  final bool floatingInput;

  const ChatView({
    super.key,
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.onSendText,
    this.onAttachmentTap,
    this.onAudioTap,
    this.onMicLongPressStart,
    this.onMicLongPressEnd,
    this.isRecording = false,
    this.showAudioPreview = false,
    this.audioPreviewWidget,
    this.recordingOverlay,
    this.onLoadMore,
    this.onMessageLongPress,
    this.onAttachmentTap2,
    this.onBusinessObjectTap,
    this.onAudioMessageTap,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isSending = false,
    this.emptyWidget,
    this.showAttachmentButton = true,
    this.showAudioButton = true,
    this.businessObjectBuilder,
    this.reactionBuilder,
    this.onReactionTap,
    this.floatingInput = false,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMoreMessages || widget.isLoadingMore) return;

    // Charger plus quand on approche du haut
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ChatMessagesList(
                scrollController: _scrollController,
                conversation: widget.conversation,
                messages: widget.messages,
                currentUserId: widget.currentUserId,
                isLoadingMore: widget.isLoadingMore,
                emptyWidget: widget.emptyWidget,
                onMessageLongPress: widget.onMessageLongPress,
                onAttachmentTap2: widget.onAttachmentTap2,
                onBusinessObjectTap: widget.onBusinessObjectTap,
                onAudioMessageTap: widget.onAudioMessageTap,
                businessObjectBuilder: widget.businessObjectBuilder,
                reactionBuilder: widget.reactionBuilder,
                onReactionTap: widget.onReactionTap,
              ),
            ),
            MessageInput(
              onSendText: widget.onSendText,
              onAttachmentTap: widget.onAttachmentTap,
              onAudioTap: widget.onAudioTap,
              onMicLongPressStart: widget.onMicLongPressStart,
              onMicLongPressEnd: widget.onMicLongPressEnd,
              isRecording: widget.isRecording,
              showAudioPreview: widget.showAudioPreview,
              audioPreviewWidget: widget.audioPreviewWidget,
              showAttachmentButton: widget.showAttachmentButton,
              showAudioButton: widget.showAudioButton,
              enabled: !widget.isSending,
              floating: widget.floatingInput,
            ),
          ],
        ),
        if (widget.isRecording && widget.recordingOverlay != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: Center(child: widget.recordingOverlay!),
          ),
      ],
    );
  }
}
