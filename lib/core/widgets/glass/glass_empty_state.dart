import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A glass-style card for displaying empty states with optional action.
///
/// Designed for dark backgrounds with glassmorphism effect.
///
/// Usage:
/// ```dart
/// GlassEmptyState(
///   icon: FontAwesomeIcons.inbox,
///   title: 'Aucun message',
///   subtitle: 'Vous n\'avez pas encore de messages',
///   actionLabel: 'Démarrer une conversation',
///   onAction: () => navigateToNewConversation(),
/// )
/// ```
class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final List<Color>? actionGradient;

  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.actionGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              )
            : null,
        color: isDark ? null : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : cs.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              icon,
              size: 24,
              color: iconColor ?? (isDark ? const Color(0xFFB0C4DE) : cs.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFB0C4DE) : cs.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            GlassActionButton(
              label: actionLabel!,
              onTap: onAction!,
              gradient: actionGradient,
            ),
          ],
        ],
      ),
    );
  }
}

/// A gradient action button used within glass components.
class GlassActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color>? gradient;

  const GlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
  });

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradient ?? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
