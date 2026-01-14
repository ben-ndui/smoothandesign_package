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
  final IconData icon;
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(icon, size: iconSize ?? 14, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
