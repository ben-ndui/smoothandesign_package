import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Glass button with gradient and glow effect.
///
/// Features:
/// - Primary (white gradient) and secondary (transparent) variants
/// - Loading state with spinner
/// - Press feedback with scale animation
/// - Optional icon
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final FaIconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.padding,
  });

  /// Secondary variant (transparent background)
  const GlassButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : isPrimary = false;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF0F0F0)],
                  )
                : null,
            color: widget.isPrimary ? null : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.isPrimary ? Colors.black54 : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        FaIcon(
                          widget.icon,
                          size: 16,
                          color: widget.isPrimary ? Colors.black87 : Colors.white,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isPrimary ? Colors.black87 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Glass social button for OAuth providers.
///
/// Features:
/// - Backdrop blur effect
/// - Loading state
/// - Ink splash feedback
class GlassSocialButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color? iconColor;

  const GlassSocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.isLoading = false,
    required this.onPressed,
    this.iconColor,
  });

  /// Google sign-in button
  factory GlassSocialButton.google({
    Key? key,
    required VoidCallback onPressed,
    bool isLoading = false,
    String label = 'Continuer avec Google',
  }) {
    return GlassSocialButton(
      key: key,
      icon: FontAwesomeIcons.google,
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  /// Apple sign-in button
  factory GlassSocialButton.apple({
    Key? key,
    required VoidCallback onPressed,
    bool isLoading = false,
    String label = 'Continuer avec Apple',
  }) {
    return GlassSocialButton(
      key: key,
      icon: FontAwesomeIcons.apple,
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.12),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    FaIcon(icon, size: 20, color: iconColor ?? Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
