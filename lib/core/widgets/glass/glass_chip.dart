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
  final IconData? icon;
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                FaIcon(widget.icon, size: 12, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (widget.showChevron) ...[
                const SizedBox(width: 4),
                const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
