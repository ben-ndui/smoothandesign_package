import 'package:just_audio/just_audio.dart';

/// Service de lecture audio réutilisable.
///
/// Utilise le package `just_audio` pour la lecture.
/// Fournit des streams pour la position et l'état du lecteur.
class AudioPlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration? _totalDuration;

  /// Durée totale du fichier audio chargé.
  Duration? get totalDuration => _totalDuration;

  /// Position actuelle de lecture.
  Duration get position => _audioPlayer.position;

  /// Vérifie si le lecteur est en train de jouer.
  bool get isPlaying => _audioPlayer.playing;

  /// Charge un fichier audio depuis une URL.
  Future<Duration?> loadFromUrl(String url) async {
    try {
      _totalDuration = await _audioPlayer.setUrl(url);
      return _totalDuration;
    } catch (_) {
      return null;
    }
  }

  /// Charge un fichier audio depuis un chemin local.
  Future<Duration?> loadFromFile(String path) async {
    try {
      _totalDuration = await _audioPlayer.setFilePath(path);
      return _totalDuration;
    } catch (_) {
      return null;
    }
  }

  /// Démarre la lecture.
  Future<void> play() async {
    if (_audioPlayer.position >= (_totalDuration ?? Duration.zero)) {
      await _audioPlayer.seek(Duration.zero);
    }
    await _audioPlayer.play();
  }

  /// Met en pause la lecture.
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Arrête la lecture et revient au début.
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
  }

  /// Déplace la position de lecture.
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Stream de la position actuelle.
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// Stream de la durée totale.
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  /// Stream de l'état du lecteur.
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Stream indiquant si la lecture est terminée.
  Stream<bool> get completedStream => _audioPlayer.playerStateStream.map(
        (state) => state.processingState == ProcessingState.completed,
      );

  /// Réinitialise le lecteur.
  Future<void> reset() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
    _totalDuration = null;
  }

  /// Libère les ressources.
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
