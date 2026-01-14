import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/smooth_firebase.dart';
import '../models/smooth_response.dart';

/// Service de stockage Firebase Storage de base.
///
/// Fournit des méthodes génériques pour upload/download de fichiers.
class BaseStorageService {
  /// Upload un fichier vers Firebase Storage.
  ///
  /// [file] - Fichier local à uploader
  /// [path] - Chemin de destination (ex: 'documents/user123/file.pdf')
  /// Retourne l'URL de téléchargement.
  Future<SmoothResponse<String>> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      final ref = SmoothFirebase.storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return SmoothResponse(
        data: downloadUrl,
        message: "Fichier uploadé avec succès",
        code: 200,
      );
    } catch (e) {
      return SmoothResponse(
        message: "Erreur lors de l'upload: $e",
        code: 500,
      );
    }
  }

  /// Upload un fichier avec timestamp automatique.
  Future<SmoothResponse<String>> uploadFileWithTimestamp({
    required File file,
    required String basePath,
    required String fileName,
    String? extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = extension ?? _getExtension(file.path);
    final path = '$basePath/${fileName}_$timestamp$ext';

    return uploadFile(file: file, path: path);
  }

  /// Upload une image de profil.
  Future<SmoothResponse<String>> uploadProfilePhoto({
    required File file,
    required String userId,
  }) async {
    return uploadFileWithTimestamp(
      file: file,
      basePath: 'profile_photos/$userId',
      fileName: 'photo',
      extension: '.jpg',
    );
  }

  /// Upload un document PDF.
  Future<SmoothResponse<String>> uploadPdf({
    required File file,
    required String userId,
    required String documentType,
    required String documentId,
  }) async {
    return uploadFileWithTimestamp(
      file: file,
      basePath: '$documentType/$userId',
      fileName: documentId,
      extension: '.pdf',
    );
  }

  /// Upload un logo.
  Future<SmoothResponse<String>> uploadLogo({
    required File file,
    required String userId,
    String? entityId,
  }) async {
    final basePath = entityId != null
        ? 'logos/$userId/$entityId'
        : 'logos/$userId';

    return uploadFileWithTimestamp(
      file: file,
      basePath: basePath,
      fileName: 'logo',
      extension: '.png',
    );
  }

  /// Télécharge un fichier depuis Firebase Storage.
  ///
  /// [storagePath] - Chemin Firebase Storage
  /// [localPath] - Chemin local où sauvegarder le fichier
  /// Utilise un cache local si le fichier existe déjà.
  Future<SmoothResponse<File>> downloadFile({
    required String storagePath,
    required String localPath,
    bool useCache = true,
  }) async {
    try {
      final localFile = File(localPath);

      // Vérifier le cache
      if (useCache && await localFile.exists()) {
        final size = await localFile.length();
        if (size > 1024) {
          return SmoothResponse(
            data: localFile,
            message: "Fichier chargé depuis le cache",
            code: 200,
          );
        } else {
          await localFile.delete();
        }
      }

      // Télécharger depuis Firebase
      final ref = SmoothFirebase.storage.ref(storagePath);
      await ref.writeToFile(localFile);

      return SmoothResponse(
        data: localFile,
        message: "Fichier téléchargé avec succès",
        code: 200,
      );
    } on FirebaseException catch (e) {
      return SmoothResponse(
        message: "Erreur Firebase: ${e.message}",
        code: 500,
      );
    } catch (e) {
      return SmoothResponse(
        message: "Erreur téléchargement: $e",
        code: 500,
      );
    }
  }

  /// Récupère l'URL de téléchargement d'un fichier.
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = SmoothFirebase.storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Supprime un fichier de Firebase Storage.
  Future<SmoothResponse<void>> deleteFile(String storagePath) async {
    try {
      final ref = SmoothFirebase.storage.ref(storagePath);
      await ref.delete();

      return SmoothResponse(
        message: "Fichier supprimé",
        code: 200,
      );
    } catch (e) {
      return SmoothResponse(
        message: "Erreur suppression: $e",
        code: 500,
      );
    }
  }

  /// Vérifie si un fichier existe.
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = SmoothFirebase.storage.ref(storagePath);
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Récupère les métadonnées d'un fichier.
  Future<FullMetadata?> getMetadata(String storagePath) async {
    try {
      final ref = SmoothFirebase.storage.ref(storagePath);
      return await ref.getMetadata();
    } catch (_) {
      return null;
    }
  }

  String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}
