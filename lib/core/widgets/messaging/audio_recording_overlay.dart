import 'package:flutter/material.dart';

/// Overlay affiché pendant l'enregistrement audio.
///
/// Affiche un timer, une visualisation waveform et un hint pour arrêter.
class AudioRecordingOverlay extends StatelessWidget {
  final int duration;

  const AudioRecordingOverlay({super.key, required this.duration});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.error, colorScheme.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMicIcon(colorScheme),
          const SizedBox(width: 12),
          _buildTimer(colorScheme),
          const SizedBox(width: 16),
          _buildWaveform(colorScheme),
          const SizedBox(width: 12),
          _buildHintText(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMicIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.onError.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.mic, color: colorScheme.onError, size: 20),
    );
  }

  Widget _buildTimer(ColorScheme colorScheme) {
    return Text(
      _formatDuration(duration),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onError,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildWaveform(ColorScheme colorScheme) {
    return Row(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            width: 3,
            height: 12 + (index % 3) * 6,
            decoration: BoxDecoration(
              color: colorScheme.onError.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintText(ColorScheme colorScheme) {
    return Text(
      'Relâcher pour arrêter',
      style: TextStyle(
        fontSize: 13,
        color: colorScheme.onError.withValues(alpha: 0.9),
      ),
    );
  }
}
