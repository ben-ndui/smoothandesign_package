import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// Widget pour prévisualiser un audio avant envoi.
///
/// Affiche les contrôles play/pause, un slider, et les boutons envoyer/supprimer.
class AudioPreviewWidget extends StatefulWidget {
  final String audioPath;
  final int duration;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  const AudioPreviewWidget({
    super.key,
    required this.audioPath,
    required this.duration,
    required this.onSend,
    required this.onDelete,
  });

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setFilePath(widget.audioPath);
      _audioPlayer.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) setState(() => _totalDuration = duration);
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDeleteButton(colorScheme),
          const SizedBox(width: 8),
          _buildPlayPauseButton(colorScheme),
          const SizedBox(width: 12),
          Expanded(child: _buildSliderAndDuration(colorScheme)),
          const SizedBox(width: 8),
          _buildSendButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: FaIcon(FontAwesomeIcons.trash, color: colorScheme.error, size: 16),
        onPressed: widget.onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildPlayPauseButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSliderAndDuration(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.3),
            thumbColor: colorScheme.primary,
          ),
          child: Slider(
            value: _totalDuration.inSeconds > 0
                ? _position.inSeconds.toDouble()
                : 0,
            max: _totalDuration.inSeconds > 0
                ? _totalDuration.inSeconds.toDouble()
                : 1,
            onChanged: (value) =>
                _audioPlayer.seek(Duration(seconds: value.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _totalDuration.inSeconds > 0
                ? '${_formatDuration(_position)} / ${_formatDuration(_totalDuration)}'
                : _formatDuration(Duration(seconds: widget.duration)),
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: FaIcon(
          FontAwesomeIcons.paperPlane,
          color: colorScheme.onPrimary,
          size: 16,
        ),
        onPressed: widget.onSend,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
