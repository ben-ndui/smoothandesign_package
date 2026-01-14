import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Service d'enregistrement audio réutilisable.
///
/// Utilise le package `record` pour l'enregistrement.
/// Gère les permissions et fournit un stream d'amplitude pour les visualisations.
class AudioRecordService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Vérifie si l'application a la permission d'accéder au microphone.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Démarre un enregistrement audio.
  ///
  /// [filePath] - Chemin où le fichier sera sauvegardé (format .m4a recommandé).
  Future<void> startRecording(String filePath) async {
    if (await hasPermission()) {
      await _recorder.start(const RecordConfig(), path: filePath);
    } else {
      throw Exception('Permission microphone refusée');
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier.
  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Vérifie si un enregistrement est en cours.
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Retourne l'amplitude actuelle (pour les visualisations).
  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  /// Stream d'amplitude pour les visualisations temps réel.
  ///
  /// Émet une valeur toutes les 100ms pendant l'enregistrement.
  Stream<Amplitude> get onAmplitudeChanged =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  /// Stream d'amplitude normalisé entre 0 et 1.
  Stream<double> amplitudeStream() async* {
    while (await isRecording()) {
      final amplitude = await getAmplitude();
      // Normalise entre 0 et 1 (l'amplitude est généralement entre -160 et 0 dB)
      final normalized = (amplitude.current + 160) / 160;
      yield normalized.clamp(0.0, 1.0);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Libère les ressources.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
