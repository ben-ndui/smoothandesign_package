import 'package:flutter/material.dart';

/// Widget de chargement animé avec effet de pulse.
///
/// Peut utiliser un logo personnalisé ou l'icône par défaut.
/// Supporte les variants fullScreen et compact.
///
/// Usage:
/// ```dart
/// // Avec logo personnalisé
/// AppLoader(logoPath: 'assets/logo/app_logo.png')
///
/// // Plein écran
/// AppLoader.fullScreen(logoPath: 'assets/logo/app_logo.png', text: 'Chargement...')
///
/// // Compact
/// AppLoader.compact()
///
/// // Avec icône par défaut
/// AppLoader(useDefaultIcon: true)
/// ```
class AppLoader extends StatelessWidget {
  /// Taille du logo (par défaut 80)
  final double size;

  /// Afficher le texte sous le logo
  final bool showText;

  /// Texte personnalisé à afficher
  final String? text;

  /// Couleur de fond (null = transparent)
  final Color? backgroundColor;

  /// Afficher le loader en plein écran avec Scaffold
  final bool fullScreen;

  /// Chemin vers l'asset du logo (optionnel)
  final String? logoPath;

  /// Utiliser l'icône par défaut au lieu d'un logo
  final bool useDefaultIcon;

  /// Couleur de l'effet glow (défaut: couleur primaire du thème)
  final Color? glowColor;

  /// Icône personnalisée (si useDefaultIcon est true)
  final IconData? icon;

  const AppLoader({
    super.key,
    this.size = 80,
    this.showText = false,
    this.text,
    this.backgroundColor,
    this.fullScreen = false,
    this.logoPath,
    this.useDefaultIcon = false,
    this.glowColor,
    this.icon,
  });

  /// Constructeur pour un loader plein écran
  const AppLoader.fullScreen({
    super.key,
    this.size = 100,
    this.showText = true,
    this.text,
    this.backgroundColor,
    this.logoPath,
    this.useDefaultIcon = false,
    this.glowColor,
    this.icon,
  }) : fullScreen = true;

  /// Constructeur pour un loader compact (dans une liste, etc.)
  const AppLoader.compact({
    super.key,
    this.showText = false,
    this.text,
    this.backgroundColor,
    this.fullScreen = false,
    this.logoPath,
    this.useDefaultIcon = true,
    this.glowColor,
    this.icon,
  }) : size = 48;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (fullScreen) {
      return Scaffold(
        backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: content),
      );
    }

    if (backgroundColor != null) {
      return Container(
        color: backgroundColor,
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedLoader(
          size: size,
          logoPath: logoPath,
          useDefaultIcon: useDefaultIcon || logoPath == null,
          glowColor: glowColor ?? theme.colorScheme.primary,
          icon: icon,
        ),
        if (showText || text != null) ...[
          const SizedBox(height: 16),
          Text(
            text ?? 'Chargement...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo/Icon animé avec effet de pulse
class _AnimatedLoader extends StatefulWidget {
  final double size;
  final String? logoPath;
  final bool useDefaultIcon;
  final Color glowColor;
  final IconData? icon;

  const _AnimatedLoader({
    required this.size,
    this.logoPath,
    required this.useDefaultIcon,
    required this.glowColor,
    this.icon,
  });

  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.25),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: widget.useDefaultIcon
                  ? _buildDefaultIcon()
                  : _buildLogo(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * 0.25),
      child: Image.asset(
        widget.logoPath!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.glowColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.size * 0.25),
        border: Border.all(
          color: widget.glowColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: widget.glowColor,
          ),
        ),
      ),
    );
  }
}
