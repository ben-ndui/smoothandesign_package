import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Widget pour afficher un message audio avec contrôles de lecture.
///
/// Affiche un bouton play/pause, un slider de progression et la durée.
class MessageAudioCard extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int? durationSeconds;

  const MessageAudioCard({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.durationSeconds,
  });

  @override
  State<MessageAudioCard> createState() => _MessageAudioCardState();
}

class _MessageAudioCardState extends State<MessageAudioCard> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  @override
  void didUpdateWidget(covariant MessageAudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Réinitialiser le player si l'URL audio change
    if (oldWidget.audioUrl != widget.audioUrl) {
      _audioPlayer.stop();
      _position = Duration.zero;
      _totalDuration = Duration.zero;
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _audioPlayer.setUrl(widget.audioUrl);
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
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ MessageAudioCard error: $e');
      debugPrint('❌ Audio URL: ${widget.audioUrl}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (widget.isMe ? colorScheme.onPrimary : colorScheme.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _error != null
          ? _buildErrorState(colorScheme)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayPauseButton(colorScheme),
                const SizedBox(width: 12),
                Flexible(child: _buildSliderAndDuration(colorScheme)),
              ],
            ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    final color = widget.isMe ? colorScheme.onPrimary : colorScheme.error;
    return GestureDetector(
      onTap: _initAudio,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Erreur audio - Appuyer pour réessayer',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(ColorScheme colorScheme) {
    final color = widget.isMe ? colorScheme.onPrimary : colorScheme.primary;

    return GestureDetector(
      onTap: _isLoading ? null : _togglePlayPause,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
        ),
        child: _isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: color,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildSliderAndDuration(ColorScheme colorScheme) {
    final activeColor =
        widget.isMe ? colorScheme.onPrimary : colorScheme.primary;
    final inactiveColor = activeColor.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            thumbColor: activeColor,
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
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            _totalDuration.inSeconds > 0
                ? '${_formatDuration(_position)} / ${_formatDuration(_totalDuration)}'
                : widget.durationSeconds != null
                    ? _formatDuration(Duration(seconds: widget.durationSeconds!))
                    : '00:00',
            style: TextStyle(
              fontSize: 11,
              color: (widget.isMe ? colorScheme.onPrimary : colorScheme.onSurface)
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
