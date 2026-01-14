import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A small action button for accept/decline actions in dashboards.
///
/// Usage:
/// ```dart
/// Row(
///   children: [
///     DashboardActionButton(
///       icon: FontAwesomeIcons.check,
///       color: Colors.green,
///       onTap: () => acceptRequest(),
///     ),
///     const SizedBox(width: 8),
///     DashboardActionButton(
///       icon: FontAwesomeIcons.xmark,
///       color: Colors.red,
///       onTap: () => declineRequest(),
///     ),
///   ],
/// )
/// ```
class DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? size;
  final double? iconSize;

  const DashboardActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size,
    this.iconSize,
  });

  /// Accept button (green checkmark).
  factory DashboardActionButton.accept({
    Key? key,
    required VoidCallback onTap,
  }) {
    return DashboardActionButton(
      key: key,
      icon: FontAwesomeIcons.check,
      color: Colors.green,
      onTap: onTap,
    );
  }

  /// Decline button (red X).
  factory DashboardActionButton.decline({
    Key? key,
    required VoidCallback onTap,
  }) {
    return DashboardActionButton(
      key: key,
      icon: FontAwesomeIcons.xmark,
      color: Colors.red,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(size ?? 10),
          child: FaIcon(icon, size: iconSize ?? 14, color: color),
        ),
      ),
    );
  }
}
