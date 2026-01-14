import 'package:flutter/material.dart';

/// Carte avec effet shimmer pour les états de chargement.
///
/// Usage:
/// ```dart
/// // Taille par défaut
/// ShimmerCard()
///
/// // Taille personnalisée
/// ShimmerCard(height: 120, width: double.infinity)
///
/// // Liste de shimmers
/// ShimmerCard.list(count: 5, height: 80)
/// ```
class ShimmerCard extends StatefulWidget {
  /// Hauteur de la carte
  final double height;

  /// Largeur de la carte (null = infinie)
  final double? width;

  /// Rayon des coins
  final double borderRadius;

  /// Couleurs du shimmer (pour thèmes sombres/clairs)
  final List<Color>? colors;

  /// Durée de l'animation
  final Duration duration;

  const ShimmerCard({
    super.key,
    this.height = 90,
    this.width,
    this.borderRadius = 20,
    this.colors,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Crée une liste de shimmer cards.
  static Widget list({
    Key? key,
    int count = 3,
    double height = 90,
    double spacing = 12,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < count - 1 ? spacing : 0),
            child: ShimmerCard(height: height, borderRadius: borderRadius),
          );
        }),
      ),
    );
  }

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultColors = isDark
        ? [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ]
        : [
            Colors.grey.withValues(alpha: 0.1),
            Colors.grey.withValues(alpha: 0.2),
            Colors.grey.withValues(alpha: 0.1),
          ];

    final shimmerColors = widget.colors ?? defaultColors;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: shimmerColors,
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder shimmer pour du texte.
class ShimmerText extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = isDark
        ? [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ]
        : [
            Colors.grey.withValues(alpha: 0.1),
            Colors.grey.withValues(alpha: 0.2),
            Colors.grey.withValues(alpha: 0.1),
          ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder shimmer circulaire (pour avatars).
class ShimmerCircle extends StatefulWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 48});

  @override
  State<ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = isDark
        ? [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ]
        : [
            Colors.grey.withValues(alpha: 0.1),
            Colors.grey.withValues(alpha: 0.2),
            Colors.grey.withValues(alpha: 0.1),
          ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}
