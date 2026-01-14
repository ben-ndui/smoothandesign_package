import 'package:flutter/material.dart';

/// A section title widget with optional count badge.
///
/// Usage:
/// ```dart
/// DashboardSectionTitle(
///   title: 'Demandes en attente',
///   count: 3,
///   countColor: Colors.orange,
/// )
/// ```
class DashboardSectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  final Color? countColor;
  final Widget? trailing;

  const DashboardSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.countColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = countColor ?? Colors.orange;

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
