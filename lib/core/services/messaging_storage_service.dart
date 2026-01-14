import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/base_message.dart';
import '../models/smooth_response.dart';

/// Service pour uploader les fichiers de messagerie vers Firebase Storage.
///
/// Gère l'upload des fichiers audio et des pièces jointes.
class MessagingStorageService {
  final FirebaseStorage _storage;

  MessagingStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload un fichier audio et retourne l'AudioAttachment.
  ///
  /// Le fichier est stocké dans `messaging/{conversationId}/audio/{timestamp}_voice.m4a`
  Future<SmoothResponse<AudioAttachment>> uploadAudio({
    required File file,
    required String conversationId,
    required int durationSeconds,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'messaging/$conversationId/audio/${timestamp}_voice.m4a';

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'audio/m4a'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final attachment = AudioAttachment(
        url: downloadUrl,
        durationSeconds: durationSeconds,
      );

      return SmoothResponse(
        code: 200,
        message: 'Audio uploadé',
        data: attachment,
      );
    } catch (e) {
      return SmoothResponse(
        code: 500,
        message: 'Erreur upload audio: $e',
        data: null,
      );
    }
  }

  /// Upload un fichier (image, document) et retourne le MessageAttachment.
  ///
  /// Le fichier est stocké dans `messaging/{conversationId}/{timestamp}_{filename}`
  Future<SmoothResponse<MessageAttachment>> uploadFile({
    required File file,
    required String conversationId,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final mimeType = _getMimeType(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'messaging/$conversationId/${timestamp}_$fileName';

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      String? thumbnailUrl;
      if (mimeType.startsWith('image/')) {
        thumbnailUrl = downloadUrl;
      }

      final attachment = MessageAttachment(
        url: downloadUrl,
        fileName: fileName,
        fileType: mimeType,
        fileSize: fileSize,
        thumbnailUrl: thumbnailUrl,
      );

      return SmoothResponse(
        code: 200,
        message: 'Fichier uploadé',
        data: attachment,
      );
    } catch (e) {
      return SmoothResponse(
        code: 500,
        message: 'Erreur upload fichier: $e',
        data: null,
      );
    }
  }

  /// Supprime un fichier du storage.
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'm4a':
        return 'audio/m4a';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
