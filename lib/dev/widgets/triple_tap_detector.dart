import 'package:flutter/material.dart';

/// Widget qui détecte les triple-taps (ou N-taps configurables).
///
/// Utile pour activer des modes secrets comme la Dev Console.
/// ```dart
/// TripleTapDetector(
///   onTripleTap: () => context.push('/dev-console'),
///   child: Text('Version 1.0.0'),
/// )
/// ```
class TripleTapDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTripleTap;
  final Duration tapInterval;
  final int requiredTaps;

  const TripleTapDetector({
    super.key,
    required this.child,
    required this.onTripleTap,
    this.tapInterval = const Duration(milliseconds: 500),
    this.requiredTaps = 3,
  });

  @override
  State<TripleTapDetector> createState() => _TripleTapDetectorState();
}

class _TripleTapDetectorState extends State<TripleTapDetector> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTap != null && now.difference(_lastTap!) < widget.tapInterval) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTap = now;

    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      _lastTap = null;
      widget.onTripleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
