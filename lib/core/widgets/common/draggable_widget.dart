import 'package:flutter/material.dart';

/// Free-form draggable widget — position librement n'importe où sur l'écran.
/// Doit être placé dans un [Stack].
///
/// Pattern porté depuis afrovibes pour mutualisation entre apps Smooth & Design.
///
/// Usage minimal :
/// ```dart
/// Stack(
///   children: [
///     // ... contenu de fond
///     DraggableWidget(
///       initialX: 16,
///       initialY: 100,
///       child: MyChip(),
///     ),
///   ],
/// );
/// ```
///
/// Ou via l'extension fluent :
/// ```dart
/// MyChip().makeDraggable(initialX: 16, initialY: 100);
/// ```
class DraggableWidget extends StatefulWidget {
  /// Widget à rendre draggable.
  final Widget child;

  /// Position initiale en pixels depuis le coin haut-gauche du parent Stack.
  final double initialX;
  final double initialY;

  /// Callback déclenché à chaque update de position et au snap final.
  final void Function(Offset)? onPositionChanged;

  /// Si vrai, contraint le widget à l'écran après chaque drag (snap aux
  /// bords si dragué hors-écran). Par défaut `true`.
  final bool constrainToScreen;

  /// Marges intérieures appliquées lors de la contrainte écran.
  final EdgeInsets screenPadding;

  /// Durée de l'animation de scale au drag.
  final Duration animationDuration;

  /// Active l'animation de scale + l'ombre portée pendant le drag.
  /// Par défaut `true`.
  final bool enableFeedback;

  const DraggableWidget({
    super.key,
    required this.child,
    this.initialX = 50.0,
    this.initialY = 100.0,
    this.onPositionChanged,
    this.constrainToScreen = true,
    this.screenPadding = const EdgeInsets.all(16.0),
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableFeedback = true,
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with TickerProviderStateMixin {
  late double _x;
  late double _y;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _x = widget.initialX;
    _y = widget.initialY;

    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _constrainToScreen(Size screenSize, Size childSize) {
    if (!widget.constrainToScreen) return;
    _x = _x.clamp(
      widget.screenPadding.left,
      screenSize.width - childSize.width - widget.screenPadding.right,
    );
    _y = _y.clamp(
      widget.screenPadding.top,
      screenSize.height - childSize.height - widget.screenPadding.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          if (widget.enableFeedback) _scaleController.forward();
        },
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
          widget.onPositionChanged?.call(Offset(_x, _y));
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          if (widget.enableFeedback) _scaleController.reverse();

          // Snap aux bords après drag (post-frame pour avoir une vraie
          // taille mesurée du child via RenderBox).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null && mounted) {
              final screenSize = MediaQuery.of(context).size;
              final childSize = renderBox.size;
              final oldX = _x;
              final oldY = _y;
              _constrainToScreen(screenSize, childSize);
              if (oldX != _x || oldY != _y) {
                setState(() {});
                widget.onPositionChanged?.call(Offset(_x, _y));
              }
            }
          });
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableFeedback && _isDragging
                  ? _scaleAnimation.value
                  : 1.0,
              child: Container(
                decoration: _isDragging && widget.enableFeedback
                    ? BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      )
                    : null,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Extension fluent pour rendre un widget draggable en chaînant un appel.
extension DraggableWidgetExtension on Widget {
  DraggableWidget makeDraggable({
    Key? key,
    double initialX = 50.0,
    double initialY = 100.0,
    void Function(Offset)? onPositionChanged,
    bool constrainToScreen = true,
    EdgeInsets screenPadding = const EdgeInsets.all(16.0),
    Duration animationDuration = const Duration(milliseconds: 200),
    bool enableFeedback = true,
  }) {
    return DraggableWidget(
      key: key,
      initialX: initialX,
      initialY: initialY,
      onPositionChanged: onPositionChanged,
      constrainToScreen: constrainToScreen,
      screenPadding: screenPadding,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      child: this,
    );
  }
}
