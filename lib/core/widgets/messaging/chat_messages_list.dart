import 'package:flutter/material.dart';
import '../../models/base_message.dart';
import '../../models/base_conversation.dart';
import 'message_bubble.dart';

/// Liste des messages d'une conversation, extraite de [ChatView] (audit
/// 2026-10-30, fichier passé au-delà des 250 lignes) : affichage, séparateurs
/// de date et état vide — [ChatView] ne garde que l'orchestration (saisie,
/// enregistrement audio, pagination).
class ChatMessagesList extends StatelessWidget {
  final ScrollController scrollController;
  final BaseConversation conversation;
  final List<BaseMessage> messages;
  final String currentUserId;
  final bool isLoadingMore;
  final Widget? emptyWidget;
  final Function(BaseMessage)? onMessageLongPress;
  final Function(BaseMessage)? onAttachmentTap2;
  final Function(BaseMessage)? onBusinessObjectTap;
  final Function(BaseMessage)? onAudioMessageTap;
  final Widget Function(BusinessObjectAttachment bo, bool isMe)? businessObjectBuilder;
  final Widget Function(Map<String, List<String>> reactions, String? currentUserId)? reactionBuilder;
  final void Function(BaseMessage message, String emoji)? onReactionTap;

  const ChatMessagesList({
    super.key,
    required this.scrollController,
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    this.isLoadingMore = false,
    this.emptyWidget,
    this.onMessageLongPress,
    this.onAttachmentTap2,
    this.onBusinessObjectTap,
    this.onAudioMessageTap,
    this.businessObjectBuilder,
    this.reactionBuilder,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoadingMore && index == messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Inverse l'index car la liste est inversée
        final realIndex = messages.length - 1 - index;
        final message = messages[realIndex];
        final isMe = message.senderId == currentUserId;

        // Afficher le nom du sender pour les groupes
        final showSenderName = conversation.type == ConversationType.group && !isMe;

        // Afficher la date si c'est le premier message du jour
        final showDate = _shouldShowDate(realIndex);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(context, message.sentAt),
            MessageBubble(
              message: message,
              isMe: isMe,
              showSenderName: showSenderName,
              onLongPress: () => onMessageLongPress?.call(message),
              onAttachmentTap: () => onAttachmentTap2?.call(message),
              onBusinessObjectTap: () => onBusinessObjectTap?.call(message),
              onAudioTap: () => onAudioMessageTap?.call(message),
              businessObjectBuilder: businessObjectBuilder,
              reactionBuilder: reactionBuilder,
              currentUserId: currentUserId,
              onReactionTap: onReactionTap != null
                  ? (emoji) => onReactionTap!(message, emoji)
                  : null,
              otherParticipantIds: conversation.participantIds
                  .where((id) => id != currentUserId)
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    final current = messages[index];
    final previous = messages[index - 1];

    return !_isSameDay(current.sentAt, previous.sentAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
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

  Widget _buildDefaultEmpty(BuildContext context) {
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
