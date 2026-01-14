import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/smooth_response.dart';

/// Configuration pour les textes du bottom sheet de sélection d'image.
class ImagePickerStrings {
  final String title;
  final String takePhoto;
  final String takePhotoSubtitle;
  final String chooseFromGallery;
  final String chooseFromGallerySubtitle;
  final String cancel;

  const ImagePickerStrings({
    this.title = 'Changer la photo',
    this.takePhoto = 'Prendre une photo',
    this.takePhotoSubtitle = 'Utiliser la caméra',
    this.chooseFromGallery = 'Choisir dans la galerie',
    this.chooseFromGallerySubtitle = 'Sélectionner une photo existante',
    this.cancel = 'Annuler',
  });
}

/// Service de base pour gérer les photos (profil, documents, etc.).
///
/// Usage:
/// ```dart
/// final photoService = BasePhotoService();
///
/// // Sélectionner une image
/// final file = await photoService.pickImage(context);
///
/// // Upload
/// final result = await photoService.uploadPhoto(
///   userId: userId,
///   imageFile: file!,
///   path: 'profile_photos',
/// );
/// ```
class BasePhotoService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage;

  /// Configuration des textes (pour la localisation).
  final ImagePickerStrings strings;

  /// Largeur max de l'image (compression).
  final double maxWidth;

  /// Hauteur max de l'image (compression).
  final double maxHeight;

  /// Qualité de l'image (0-100).
  final int imageQuality;

  BasePhotoService({
    FirebaseStorage? storage,
    this.strings = const ImagePickerStrings(),
    this.maxWidth = 512,
    this.maxHeight = 512,
    this.imageQuality = 85,
  }) : _storage = storage ?? FirebaseStorage.instance;

  /// Affiche un bottom sheet pour choisir la source de l'image.
  Future<File?> pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(strings: strings),
    );

    if (source == null) return null;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Sélectionne une image depuis la caméra directement.
  Future<File?> pickFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Sélectionne une image depuis la galerie directement.
  Future<File?> pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Upload une photo et retourne l'URL.
  ///
  /// [path] - Chemin dans Firebase Storage (ex: 'profile_photos').
  /// [userId] - ID de l'utilisateur.
  /// [fileName] - Nom du fichier (défaut: 'photo.jpg').
  Future<SmoothResponse<String>> uploadPhoto({
    required String userId,
    required File imageFile,
    required String path,
    String fileName = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child(path).child(userId).child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return SmoothResponse(
        data: downloadUrl,
        message: 'Photo uploadée',
        code: 200,
      );
    } on FirebaseException catch (e) {
      return SmoothResponse(
        data: '',
        message: 'Erreur Firebase: ${e.message}',
        code: 500,
      );
    } catch (e) {
      return SmoothResponse(
        data: '',
        message: 'Erreur: $e',
        code: 500,
      );
    }
  }

  /// Supprime une photo.
  Future<SmoothResponse<bool>> deletePhoto({
    required String userId,
    required String path,
    String fileName = 'photo.jpg',
  }) async {
    try {
      final ref = _storage.ref().child(path).child(userId).child(fileName);
      await ref.delete();
      return SmoothResponse(data: true, message: 'Photo supprimée', code: 200);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return SmoothResponse(data: true, message: 'OK', code: 200);
      }
      return SmoothResponse(data: false, message: 'Erreur: ${e.message}', code: 500);
    }
  }
}

class _ImageSourceSheet extends StatelessWidget {
  final ImagePickerStrings strings;

  const _ImageSourceSheet({required this.strings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
              ),
              title: Text(strings.takePhoto),
              subtitle: Text(
                strings.takePhotoSubtitle,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: theme.colorScheme.secondary),
              ),
              title: Text(strings.chooseFromGallery),
              subtitle: Text(
                strings.chooseFromGallerySubtitle,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
