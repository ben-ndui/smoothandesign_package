import 'package:flutter/material.dart';

/// Animation utilities and presets.
///
/// Provides consistent animations across the app.
class AppAnimations {
  AppAnimations._();

  // Duration constants
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 700);

  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;

  /// Fade in animation.
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeInOut,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Slide + Fade animation.
  static Widget slideAndFade({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeInOut,
    Offset begin = const Offset(0, 0.3),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            begin.dx * (1 - value),
            begin.dy * (1 - value) * 50,
          ),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  /// Scale animation.
  static Widget scale({
    required Widget child,
    Duration duration = fast,
    Curve curve = easeInOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  /// Animated list item with stagger.
  static Widget listItem({
    required Widget child,
    required int index,
    Duration duration = normal,
  }) {
    return slideAndFade(
      duration: duration,
      delay: Duration(milliseconds: index * 50),
      begin: const Offset(0, 0.2),
      child: child,
    );
  }

  /// Bounce animation.
  static Widget bounceIn({
    required Widget child,
    Duration duration = slow,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: bounce,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  /// Rotation animation.
  static Widget rotate({
    required Widget child,
    Duration duration = normal,
    double turns = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: turns),
      duration: duration,
      curve: easeInOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Slide page transition for navigation.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: fadeAnimation, child: child),
            );
          },
          transitionDuration: AppAnimations.normal,
        );
}
