import 'package:flutter/material.dart';
import '../../models/base_message.dart';
import '../../models/base_conversation.dart';
import 'message_bubble.dart';
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

  /// Builder personnalisé pour les business objects (session, booking, etc.).
  final Widget Function(BusinessObjectAttachment bo, bool isMe)? businessObjectBuilder;

  /// Builder pour afficher les réactions sous les messages.
  final Widget Function(Map<String, List<String>> reactions, String? currentUserId)? reactionBuilder;

  /// Callback quand un utilisateur tape sur une réaction.
  final void Function(BaseMessage message, String emoji)? onReactionTap;

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
    this.businessObjectBuilder,
    this.reactionBuilder,
    this.onReactionTap,
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
            Expanded(child: _buildMessagesList()),
            MessageInput(
              onSendText: widget.onSendText,
              onAttachmentTap: widget.onAttachmentTap,
              onAudioTap: widget.onAudioTap,
              onMicLongPressStart: widget.onMicLongPressStart,
              onMicLongPressEnd: widget.onMicLongPressEnd,
              isRecording: widget.isRecording,
              showAudioPreview: widget.showAudioPreview,
              audioPreviewWidget: widget.audioPreviewWidget,
              enabled: !widget.isSending,
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

  Widget _buildMessagesList() {
    if (widget.messages.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.messages.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isLoadingMore && index == widget.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Inverse l'index car la liste est inversée
        final realIndex = widget.messages.length - 1 - index;
        final message = widget.messages[realIndex];
        final isMe = message.senderId == widget.currentUserId;

        // Afficher le nom du sender pour les groupes
        final showSenderName = widget.conversation.type == ConversationType.group && !isMe;

        // Afficher la date si c'est le premier message du jour
        final showDate = _shouldShowDate(realIndex);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.sentAt),
            MessageBubble(
              message: message,
              isMe: isMe,
              showSenderName: showSenderName,
              onLongPress: () => widget.onMessageLongPress?.call(message),
              onAttachmentTap: () => widget.onAttachmentTap2?.call(message),
              onBusinessObjectTap: () => widget.onBusinessObjectTap?.call(message),
              onAudioTap: () => widget.onAudioMessageTap?.call(message),
              businessObjectBuilder: widget.businessObjectBuilder,
              reactionBuilder: widget.reactionBuilder,
              currentUserId: widget.currentUserId,
              onReactionTap: widget.onReactionTap != null
                  ? (emoji) => widget.onReactionTap!(message, emoji)
                  : null,
              otherParticipantIds: widget.conversation.participantIds
                  .where((id) => id != widget.currentUserId)
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    final current = widget.messages[index];
    final previous = widget.messages[index - 1];

    return !_isSameDay(current.sentAt, previous.sentAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final diff = now.difference(date);

    String text;
    if (_isSameDay(date, now)) {
      text = "Aujourd'hui";
    } else if (diff.inDays == 1) {
      text = 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      text = days[date.weekday - 1];
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez la conversation !',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
