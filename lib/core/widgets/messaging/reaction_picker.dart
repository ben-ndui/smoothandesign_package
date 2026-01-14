import 'package:flutter/material.dart';

/// Emojis disponibles par défaut pour les réactions.
const List<String> kDefaultReactionEmojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

/// Sélecteur d'emoji pour réagir à un message.
///
/// Usage:
/// ```dart
/// // Widget direct
/// ReactionPicker(
///   onEmojiSelected: (emoji) => addReaction(emoji),
/// )
///
/// // En overlay
/// ReactionPicker.show(
///   context: context,
///   position: tapPosition,
///   onEmojiSelected: (emoji) => addReaction(emoji),
/// )
/// ```
class ReactionPicker extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;
  final List<String>? emojis;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
    this.emojis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emojiList = emojis ?? kDefaultReactionEmojis;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojiList.map((emoji) {
          return _EmojiButton(
            emoji: emoji,
            onTap: () => onEmojiSelected(emoji),
          );
        }).toList(),
      ),
    );
  }

  /// Affiche le picker en overlay au-dessus d'un message.
  static void show({
    required BuildContext context,
    required Offset position,
    required void Function(String emoji) onEmojiSelected,
    List<String>? emojis,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Picker
          Positioned(
            left: position.dx.clamp(8.0, MediaQuery.of(context).size.width - 260),
            top: position.dy - 56,
            child: ReactionPicker(
              emojis: emojis,
              onEmojiSelected: (emoji) {
                entry.remove();
                onEmojiSelected(emoji);
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}
