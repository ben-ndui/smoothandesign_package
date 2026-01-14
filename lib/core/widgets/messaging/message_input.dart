import 'package:flutter/material.dart';

/// Champ de saisie pour envoyer des messages.
class MessageInput extends StatefulWidget {
  final Function(String) onSendText;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onAudioTap;
  final VoidCallback? onMicLongPressStart;
  final VoidCallback? onMicLongPressEnd;
  final bool isRecording;
  final bool showAudioPreview;
  final Widget? audioPreviewWidget;
  final bool enabled;
  final String hintText;
  final bool showAttachmentButton;
  final bool showAudioButton;

  const MessageInput({
    super.key,
    required this.onSendText,
    this.onAttachmentTap,
    this.onAudioTap,
    this.onMicLongPressStart,
    this.onMicLongPressEnd,
    this.isRecording = false,
    this.showAudioPreview = false,
    this.audioPreviewWidget,
    this.enabled = true,
    this.hintText = 'Ecrivez un message...',
    this.showAttachmentButton = true,
    this.showAudioButton = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show audio preview if available
    if (widget.showAudioPreview && widget.audioPreviewWidget != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(child: widget.audioPreviewWidget!),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.showAttachmentButton)
              IconButton(
                onPressed: widget.enabled ? widget.onAttachmentTap : null,
                icon: const Icon(Icons.attach_file),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _onSend(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (_hasText)
              IconButton(
                onPressed: widget.enabled ? _onSend : null,
                icon: const Icon(Icons.send),
                color: theme.colorScheme.primary,
              )
            else if (widget.showAudioButton)
              _buildMicButton(theme)
            else
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.send),
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(ThemeData theme) {
    // If long press callbacks are provided, use GestureDetector
    if (widget.onMicLongPressStart != null && widget.onMicLongPressEnd != null) {
      return GestureDetector(
        onLongPressStart: widget.enabled ? (_) => widget.onMicLongPressStart?.call() : null,
        onLongPressEnd: widget.enabled ? (_) => widget.onMicLongPressEnd?.call() : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isRecording ? theme.colorScheme.error : Colors.transparent,
          ),
          child: Icon(
            Icons.mic,
            color: widget.isRecording
                ? theme.colorScheme.onError
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Otherwise use simple tap
    return IconButton(
      onPressed: widget.enabled ? widget.onAudioTap : null,
      icon: const Icon(Icons.mic),
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}
