import 'package:flutter/material.dart';

/// Affiche les réactions sous une bulle de message.
///
/// Usage:
/// ```dart
/// ReactionDisplay(
///   reactions: {
///     '❤️': ['user1', 'user2'],
///     '👍': ['user3'],
///   },
///   currentUserId: 'user1',
///   onReactionTap: (emoji) => toggleReaction(emoji),
/// )
/// ```
class ReactionDisplay extends StatelessWidget {
  /// Map des réactions: emoji -> liste des userIds qui ont réagi
  final Map<String, List<String>> reactions;

  /// ID de l'utilisateur actuel (pour highlight sa réaction)
  final String? currentUserId;

  /// Callback quand l'utilisateur tape sur une réaction
  final void Function(String emoji)? onReactionTap;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    this.currentUserId,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;
        final hasReacted = currentUserId != null && userIds.contains(currentUserId);

        return _ReactionChip(
          emoji: emoji,
          count: userIds.length,
          hasReacted: hasReacted,
          onTap: onReactionTap != null ? () => onReactionTap!(emoji) : null,
          theme: theme,
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool hasReacted;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.hasReacted,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasReacted
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: hasReacted
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasReacted
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
