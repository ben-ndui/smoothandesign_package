import 'package:flutter/material.dart';
import '../../models/base_message.dart';
import 'message_audio_card.dart';

/// Bulle de message dans un chat.
class MessageBubble extends StatelessWidget {
  final BaseMessage message;
  final bool isMe;
  final bool showAvatar;
  final bool showSenderName;
  final VoidCallback? onLongPress;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onBusinessObjectTap;
  final VoidCallback? onAudioTap;

  /// Builder personnalisé pour les business objects (session, booking, etc.).
  /// Si null, utilise le rendu par défaut.
  final Widget Function(BusinessObjectAttachment bo, bool isMe)? businessObjectBuilder;

  /// Callback pour ajouter/toggle une réaction.
  final void Function(String emoji)? onReactionTap;

  /// Builder personnalisé pour afficher les réactions sous la bulle.
  final Widget Function(Map<String, List<String>> reactions, String? currentUserId)? reactionBuilder;

  /// ID de l'utilisateur courant pour la gestion des réactions.
  final String? currentUserId;

  /// IDs des autres participants pour calculer le statut effectif (lu/non-lu).
  /// Nécessaire pour afficher les indicateurs ✓✓ sur les messages envoyés.
  final List<String>? otherParticipantIds;

  /// Afficher les indicateurs de statut (✓, ✓✓) pour les messages envoyés.
  final bool showStatusIndicators;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.showSenderName = false,
    this.onLongPress,
    this.onAttachmentTap,
    this.onBusinessObjectTap,
    this.onAudioTap,
    this.businessObjectBuilder,
    this.onReactionTap,
    this.reactionBuilder,
    this.currentUserId,
    this.otherParticipantIds,
    this.showStatusIndicators = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return _buildDeletedMessage(theme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) _buildAvatar(theme),
          if (!isMe && showAvatar) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(theme),
                if (message.reactions.isNotEmpty && reactionBuilder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: reactionBuilder!(message.reactions, currentUserId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Message supprime',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (message.senderAvatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(message.senderAvatarUrl!),
      );
    }

    final initial = message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBubble(ThemeData theme) {
    final bgColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildContent(theme, textColor),
            const SizedBox(height: 4),
            _buildTime(theme, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color textColor) {
    switch (message.type) {
      case MessageType.attachment:
        return _buildAttachmentContent(theme, textColor);
      case MessageType.businessObject:
        return _buildBusinessObjectContent(theme, textColor);
      case MessageType.audio:
        return _buildAudioContent(theme, textColor);
      default:
        return Text(
          message.text ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        );
    }
  }

  Widget _buildAttachmentContent(ThemeData theme, Color textColor) {
    final attachment = message.attachment;
    if (attachment == null) return const SizedBox.shrink();

    if (attachment.isImage) {
      return GestureDetector(
        onTap: onAttachmentTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            attachment.thumbnailUrl ?? attachment.url,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 100,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onAttachmentTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.isPdf ? Icons.picture_as_pdf : Icons.attach_file,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessObjectContent(ThemeData theme, Color textColor) {
    final bo = message.businessObject;
    if (bo == null) return const SizedBox.shrink();

    // Use custom builder if provided
    if (businessObjectBuilder != null) {
      return GestureDetector(
        onTap: onBusinessObjectTap,
        child: businessObjectBuilder!(bo, isMe),
      );
    }

    return GestureDetector(
      onTap: onBusinessObjectTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getBusinessObjectIcon(bo.objectType),
              size: 24,
              color: isMe ? textColor : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bo.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bo.clientName != null || bo.amount != null)
                    Text(
                      [
                        if (bo.clientName != null) bo.clientName,
                        if (bo.amount != null) '${bo.amount!.toStringAsFixed(2)} EUR',
                      ].join(' - '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBusinessObjectIcon(String type) {
    switch (type) {
      case 'quote':
        return Icons.description_outlined;
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'mission':
        return Icons.work_outline;
      case 'session':
        return Icons.event_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Widget _buildAudioContent(ThemeData theme, Color textColor) {
    final audio = message.audio;
    if (audio == null) return const SizedBox.shrink();

    return MessageAudioCard(
      audioUrl: audio.url,
      isMe: isMe,
      durationSeconds: audio.durationSeconds,
    );
  }

  Widget _buildTime(ThemeData theme, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.sentAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        if (message.editedAt != null) ...[
          const SizedBox(width: 4),
          Text(
            '(modifie)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        // Status indicators for sent messages
        if (isMe && showStatusIndicators) ...[
          const SizedBox(width: 4),
          _buildStatusIndicator(theme, textColor),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, Color textColor) {
    final effectiveStatus = otherParticipantIds != null
        ? message.getEffectiveStatus(otherParticipantIds!)
        : message.status;

    switch (effectiveStatus) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 14,
          color: textColor.withValues(alpha: 0.5),
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: theme.colorScheme.error,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: textColor.withValues(alpha: 0.7),
        );
      case MessageStatus.delivered:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done_all,
              size: 14,
              color: textColor.withValues(alpha: 0.7),
            ),
          ],
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.primary,
        );
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
