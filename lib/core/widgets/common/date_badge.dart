import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Badge de date compact montrant le jour et le mois.
///
/// Usage:
/// ```dart
/// DateBadge(date: DateTime.now())
///
/// // Date passée (style grisé)
/// DateBadge(date: pastDate, isPast: true)
///
/// // Couleurs personnalisées
/// DateBadge(
///   date: date,
///   gradient: [Colors.green, Colors.teal],
/// )
/// ```
class DateBadge extends StatelessWidget {
  final DateTime date;
  final bool isPast;
  final List<Color>? gradient;
  final Color? pastColor;
  final double? width;

  const DateBadge({
    super.key,
    required this.date,
    this.isPast = false,
    this.gradient,
    this.pastColor,
    this.width,
  });

  /// Crée un DateBadge qui détermine automatiquement si la date est passée.
  factory DateBadge.auto({
    Key? key,
    required DateTime date,
    List<Color>? gradient,
    Color? pastColor,
    double? width,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    return DateBadge(
      key: key,
      date: date,
      isPast: dateOnly.isBefore(today),
      gradient: gradient,
      pastColor: pastColor,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dayFormat = DateFormat('d', locale);
    final monthFormat = DateFormat('MMM', locale);

    final defaultGradient = gradient ?? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];

    return Container(
      width: width ?? 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: isPast
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: defaultGradient,
              ),
        color: isPast ? (pastColor ?? Colors.white.withValues(alpha: 0.1)) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayFormat.format(date),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isPast ? const Color(0xFFB0C4DE) : Colors.white,
            ),
          ),
          Text(
            monthFormat.format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPast
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de date horizontal (jour, mois, année).
class DateBadgeHorizontal extends StatelessWidget {
  final DateTime date;
  final bool showYear;
  final TextStyle? textStyle;

  const DateBadgeHorizontal({
    super.key,
    required this.date,
    this.showYear = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = showYear
        ? DateFormat('d MMM yyyy', locale)
        : DateFormat('d MMM', locale);

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        format.format(date),
        style: textStyle ??
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
