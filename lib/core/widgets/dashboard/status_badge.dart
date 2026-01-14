import 'package:flutter/material.dart';

/// A generic status badge widget for dashboards.
///
/// Usage:
/// ```dart
/// StatusBadge(
///   label: 'En attente',
///   color: Colors.orange,
/// )
///
/// // Or with predefined statuses
/// StatusBadge.pending(label: 'En attente')
/// StatusBadge.success(label: 'Confirmé')
/// StatusBadge.error(label: 'Annulé')
/// ```
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize,
    this.padding,
  });

  /// Pending status (orange).
  factory StatusBadge.pending({Key? key, required String label}) {
    return StatusBadge(key: key, label: label, color: Colors.orange);
  }

  /// Success status (green).
  factory StatusBadge.success({Key? key, required String label}) {
    return StatusBadge(key: key, label: label, color: Colors.green);
  }

  /// Error status (red).
  factory StatusBadge.error({Key? key, required String label}) {
    return StatusBadge(key: key, label: label, color: Colors.red);
  }

  /// Info status (blue).
  factory StatusBadge.info({Key? key, required String label}) {
    return StatusBadge(key: key, label: label, color: Colors.blue);
  }

  /// Neutral status (grey).
  factory StatusBadge.neutral({Key? key, required String label}) {
    return StatusBadge(key: key, label: label, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
