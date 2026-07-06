import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A standard settings tile with icon, title, subtitle and navigation.
///
/// Usage:
/// ```dart
/// SettingsTile(
///   icon: FontAwesomeIcons.user,
///   title: 'Profil',
///   subtitle: 'Modifier vos informations',
///   onTap: () => navigateToProfile(),
/// )
///
/// // Destructive action (red)
/// SettingsTile(
///   icon: FontAwesomeIcons.arrowRightFromBracket,
///   title: 'Déconnexion',
///   subtitle: 'Se déconnecter de l\'application',
///   onTap: () => logout(),
///   isDestructive: true,
/// )
/// ```
class SettingsTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;
  final Color? iconColor;
  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;
    final effectiveIconColor = iconColor ?? (isDestructive ? Colors.red : theme.colorScheme.primary);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 18,
            color: effectiveIconColor,
          ),
        ),
      ),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
      trailing: trailing ??
          (isDestructive || !showArrow
              ? null
              : FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 14,
                  color: theme.colorScheme.outline,
                )),
      onTap: onTap,
    );
  }
}

/// A settings tile with a switch toggle.
class SettingsSwitchTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 18,
            color: iconColor ?? theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(title),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
