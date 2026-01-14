import 'package:flutter/material.dart';

/// Indicateur de saisie animé (3 points qui rebondissent).
///
/// Peut être utilisé pour indiquer qu'un utilisateur ou une IA est en train de taper.
///
/// Usage:
/// ```dart
/// // Style simple (juste les points)
/// TypingIndicator()
///
/// // Avec conteneur et texte
/// TypingIndicator.withContainer(
///   text: 'L\'IA réfléchit...',
///   icon: Icons.auto_awesome,
/// )
/// ```
class TypingIndicator extends StatefulWidget {
  /// Couleur des points (défaut: purple)
  final Color? dotColor;

  /// Taille des points
  final double dotSize;

  /// Espacement entre les points
  final double dotSpacing;

  const TypingIndicator({
    super.key,
    this.dotColor,
    this.dotSize = 8,
    this.dotSpacing = 2,
  });

  /// Crée un indicateur avec un conteneur stylisé et un texte.
  static Widget withContainer({
    Key? key,
    String? text,
    IconData? icon,
    Color? accentColor,
  }) {
    return _TypingIndicatorWithContainer(
      key: key,
      text: text,
      icon: icon,
      accentColor: accentColor,
    );
  }

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Démarrer les animations en décalé
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ?? Colors.purple;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSpacing),
              child: Transform.translate(
                offset: Offset(0, -4 * _animations[index].value),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.5 + 0.5 * _animations[index].value,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _TypingIndicatorWithContainer extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color? accentColor;

  const _TypingIndicatorWithContainer({
    super.key,
    this.text,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? Colors.purple;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.1),
            Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
          ],
          TypingIndicator(dotColor: color),
          if (text != null) ...[
            const SizedBox(width: 12),
            Text(
              text!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
