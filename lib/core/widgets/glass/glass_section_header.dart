import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A glass-style section header with icon and title.
///
/// Designed for dark backgrounds.
///
/// Usage:
/// ```dart
/// GlassSectionHeader(
///   title: 'Mes sessions',
///   icon: FontAwesomeIcons.calendar,
/// )
/// ```
class GlassSectionHeader extends StatelessWidget {
  final String title;
  final FaIconData icon;
  final double? iconSize;
  final double? fontSize;

  const GlassSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final iconBgColor = isDark ? Colors.white.withValues(alpha: 0.15) : cs.primary.withValues(alpha: 0.12);
    final iconBgColor2 = isDark ? Colors.white.withValues(alpha: 0.08) : cs.primary.withValues(alpha: 0.06);
    final fgColor = isDark ? Colors.white : cs.onSurface;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [iconBgColor, iconBgColor2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(icon, size: iconSize ?? 14, color: isDark ? Colors.white : cs.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      ],
    );
  }
}
