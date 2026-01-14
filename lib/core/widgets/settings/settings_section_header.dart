import 'package:flutter/material.dart';

/// A section header for settings pages.
///
/// Usage:
/// ```dart
/// SettingsSectionHeader(title: 'Compte')
/// ```
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final bool uppercase;
  final EdgeInsetsGeometry? padding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.uppercase = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        uppercase ? title.toUpperCase() : title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: uppercase ? 1.2 : 0,
        ),
      ),
    );
  }
}

/// A grouped settings section with optional title and children tiles.
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) SettingsSectionHeader(title: title!),
        Container(
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
