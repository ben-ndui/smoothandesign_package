import 'package:flutter/material.dart';
import '../../models/base_conversation.dart';

/// Tuile représentant une conversation dans une liste.
class ConversationTile extends StatelessWidget {
  final BaseConversation conversation;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final displayName = conversation.getDisplayName(currentUserId);
    final avatarUrl = conversation.getAvatarUrl(currentUserId);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _buildAvatar(theme, displayName, avatarUrl),
      title: Text(
        displayName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(theme, hasUnread),
      trailing: trailing ?? _buildTrailing(theme, unreadCount),
    );
  }

  Widget _buildAvatar(ThemeData theme, String name, String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget? _buildSubtitle(ThemeData theme, bool hasUnread) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return null;

    final isMyMessage = lastMessage.senderId == currentUserId;

    return Row(
      children: [
        // Status indicator for my messages
        if (isMyMessage) ...[
          _buildLastMessageStatus(theme, lastMessage),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            lastMessage.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasUnread
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Construit l'indicateur de statut pour le dernier message envoyé.
  Widget _buildLastMessageStatus(ThemeData theme, LastMessageSummary lastMessage) {
    // Calculate effective status based on readBy
    final otherParticipantIds = conversation.participantIds
        .where((id) => id != currentUserId)
        .toList();

    // Check if any other participant has read the message
    // Note: LastMessageInfo doesn't have readBy, so we use a simplified version
    // For now, just show a single check (sent) - full read status requires
    // accessing the full message data
    final bool isRead = conversation.getUnreadCount(currentUserId) == 0 &&
        otherParticipantIds.isNotEmpty;

    if (isRead) {
      // Read - double blue check
      return Icon(
        Icons.done_all,
        size: 16,
        color: theme.colorScheme.primary,
      );
    } else {
      // Sent - single gray check
      return Icon(
        Icons.check,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
  }

  Widget _buildTrailing(ThemeData theme, int unreadCount) {
    final lastMessage = conversation.lastMessage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (lastMessage != null)
          Text(
            _formatTime(lastMessage.sentAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: unreadCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
