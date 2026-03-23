import 'package:flutter/material.dart';

/// Draggable bottom sheet collapsible avec boutons flottants.
///
/// Usage:
/// ```dart
/// // Simple
/// SmoothDraggableWidget(
///   bodyContent: MyContent(),
/// )
///
/// // Avec boutons flottants
/// SmoothDraggableWidget(
///   bodyContent: MyContent(),
///   floatButtons: [
///     FloatingActionButton(
///       onPressed: () {},
///       child: Icon(Icons.add),
///     ),
///   ],
/// )
///
/// // Avec couleurs personnalisées
/// SmoothDraggableWidget(
///   bodyContent: MyContent(),
///   gradientColors: [Colors.purple, Colors.indigo],
/// )
/// ```
class SmoothDraggableWidget extends StatefulWidget {
  /// Contenu principal du sheet.
  final Widget bodyContent;

  /// Boutons flottants affichés quand le sheet dépasse le threshold.
  final List<Widget> floatButtons;

  /// Taille maximale (1.0 = plein écran).
  final double maxSize;

  /// Taille minimale (fraction de l'écran).
  final double minSize;

  /// Taille initiale.
  final double initial;

  /// Seuil pour afficher les boutons flottants (0.0 - 1.0).
  final double threshold;

  /// Couleurs du gradient (haut vers bas).
  /// Si null, utilise les couleurs du thème.
  final List<Color>? gradientColors;

  /// Padding en bas du contenu.
  final double bottomPadding;

  /// Padding en bas des boutons flottants.
  final double floatingBottomPadding;

  /// Rayon des coins supérieurs.
  final double borderRadius;

  /// Afficher la poignée de drag.
  final bool showHandle;

  /// Couleur de la poignée.
  final Color? handleColor;

  const SmoothDraggableWidget({
    super.key,
    required this.bodyContent,
    this.floatButtons = const [],
    this.maxSize = 1.0,
    this.minSize = 0.12,
    this.initial = 0.5,
    this.threshold = 0.6,
    this.gradientColors,
    this.bottomPadding = 20,
    this.floatingBottomPadding = 40,
    this.borderRadius = 40,
    this.showHandle = true,
    this.handleColor,
  });

  @override
  State<SmoothDraggableWidget> createState() => _SmoothDraggableWidgetState();
}

class _SmoothDraggableWidgetState extends State<SmoothDraggableWidget> {
  DraggableScrollableController controller = DraggableScrollableController();
  final ValueNotifier<bool> showButtons = ValueNotifier(false);
  final ValueNotifier<bool> showDragHandle = ValueNotifier(true);
  final ValueNotifier<double> safeAreaPadding = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    controller.addListener(_onSheetScroll);
  }

  void _onSheetScroll() {
    final normalizedSize =
        (controller.size - widget.minSize) / (widget.maxSize - widget.minSize);

    // Update floating action buttons visibility
    if (controller.size <= widget.minSize) {
      if (showButtons.value != false) showButtons.value = false;
    } else if (normalizedSize > widget.threshold) {
      if (showButtons.value != true) showButtons.value = true;
    }

    // Handle drag handle visibility
    final shouldShowDragHandle = controller.size <= widget.maxSize * 0.9;
    if (showDragHandle.value != shouldShowDragHandle) {
      showDragHandle.value = shouldShowDragHandle;
    }

    // SafeArea padding management — only when sheet covers the status bar
    final shouldApplySafeArea = widget.maxSize >= 0.95;
    final safePadding = MediaQuery.of(context).padding.top;
    final targetPadding =
        (shouldApplySafeArea && controller.size >= widget.maxSize * 0.99)
            ? safePadding
            : 0;
    if (safeAreaPadding.value != targetPadding) {
      safeAreaPadding.value = targetPadding.toDouble();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    showButtons.dispose();
    showDragHandle.dispose();
    safeAreaPadding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default gradient using theme colors
    final colors = widget.gradientColors ??
        [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.surface,
        ];

    return DraggableScrollableSheet(
      initialChildSize: widget.initial,
      minChildSize: widget.minSize,
      maxChildSize: widget.maxSize,
      controller: controller,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(widget.borderRadius)),
          child: _GradientBackground(
            colors: colors,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (widget.showHandle)
                      SliverToBoxAdapter(child: _buildDragHandle()),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        ValueListenableBuilder<double>(
                          valueListenable: safeAreaPadding,
                          builder: (context, padding, child) {
                            return AnimatedPadding(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.only(
                                top: padding,
                                bottom: widget.bottomPadding,
                              ),
                              child: widget.bodyContent,
                            );
                          },
                        ),
                      ]),
                    ),
                  ],
                ),
                if (widget.floatButtons.isNotEmpty) _buildFloatButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    final handleColor =
        widget.handleColor ?? Colors.white.withValues(alpha: 0.3);

    return ValueListenableBuilder<bool>(
      valueListenable: showDragHandle,
      builder: (context, isVisible, child) {
        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatButtons() {
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: showButtons,
      builder: (context, isVisible, child) {
        return Positioned(
          right: 20,
          bottom: widget.floatingBottomPadding + bottomSafeArea,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: isVisible
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: widget.floatButtons
                        .map((btn) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: btn,
                            ))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Gradient background container.
class _GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;

  const _GradientBackground({
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: child,
    );
  }
}
