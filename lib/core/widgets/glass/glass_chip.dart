import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A tappable glass-style chip with label and chevron.
///
/// Designed for dark backgrounds with press feedback animation.
///
/// Usage:
/// ```dart
/// GlassChip(
///   label: 'Voir tout',
///   onTap: () => navigateToList(),
/// )
/// ```
class GlassChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final FaIconData? icon;
  final bool showChevron;

  const GlassChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.showChevron = true,
  });

  @override
  State<GlassChip> createState() => _GlassChipState();
}

class _GlassChipState extends State<GlassChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cs = Theme.of(context).colorScheme;
            final fgColor = isDark ? Colors.white : cs.onSurface;
            final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : cs.surfaceContainerHigh;
            final borderColor = isDark ? Colors.white.withValues(alpha: 0.2) : cs.outlineVariant;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    FaIcon(widget.icon, size: 12, color: fgColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: fgColor,
                    ),
                  ),
                  if (widget.showChevron) ...[
                    const SizedBox(width: 4),
                    FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: fgColor.withValues(alpha: 0.6)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
