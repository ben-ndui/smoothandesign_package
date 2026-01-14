import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Type de fichier à sélectionner.
enum FilePickerType {
  image,
  pdf,
  document,
  any,
}

/// Résultat d'une sélection de fichier.
class PickedFile {
  final File file;
  final String fileName;
  final String? mimeType;
  final int size;

  const PickedFile({
    required this.file,
    required this.fileName,
    this.mimeType,
    required this.size,
  });

  bool get isImage =>
      mimeType?.startsWith('image/') == true ||
      _imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));

  bool get isPdf =>
      mimeType == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
}

/// Helper pour la sélection de fichiers et images.
///
/// Fournit une API unifiée pour:
/// - Sélection d'images (galerie/caméra)
/// - Sélection de fichiers (PDF, documents, etc.)
/// - Compression d'images
class FilePickerHelper {
  final ImagePicker _imagePicker = ImagePicker();

  /// Qualité de compression par défaut (0-100).
  final int defaultImageQuality;

  /// Largeur max par défaut pour les images.
  final double defaultMaxWidth;

  /// Hauteur max par défaut pour les images.
  final double defaultMaxHeight;

  FilePickerHelper({
    this.defaultImageQuality = 85,
    this.defaultMaxWidth = 1024,
    this.defaultMaxHeight = 1024,
  });

  // ===== IMAGES =====

  /// Sélectionne une image depuis la galerie.
  Future<PickedFile?> pickImageFromGallery({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality ?? defaultImageQuality,
      maxWidth: maxWidth ?? defaultMaxWidth,
      maxHeight: maxHeight ?? defaultMaxHeight,
    );

    return _xFileToPickedFile(xFile);
  }

  /// Prend une photo avec la caméra.
  Future<PickedFile?> pickImageFromCamera({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality ?? defaultImageQuality,
      maxWidth: maxWidth ?? defaultMaxWidth,
      maxHeight: maxHeight ?? defaultMaxHeight,
    );

    return _xFileToPickedFile(xFile);
  }

  /// Sélectionne plusieurs images depuis la galerie.
  Future<List<PickedFile>> pickMultipleImages({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    int? limit,
  }) async {
    final xFiles = await _imagePicker.pickMultiImage(
      imageQuality: imageQuality ?? defaultImageQuality,
      maxWidth: maxWidth ?? defaultMaxWidth,
      maxHeight: maxHeight ?? defaultMaxHeight,
      limit: limit,
    );

    final results = <PickedFile>[];
    for (final xFile in xFiles) {
      final picked = await _xFileToPickedFile(xFile);
      if (picked != null) results.add(picked);
    }
    return results;
  }

  Future<PickedFile?> _xFileToPickedFile(XFile? xFile) async {
    if (xFile == null) return null;

    final file = File(xFile.path);
    final size = await file.length();
    final mimeType = xFile.mimeType ?? _getMimeType(xFile.name);

    return PickedFile(
      file: file,
      fileName: xFile.name,
      mimeType: mimeType,
      size: size,
    );
  }

  // ===== FICHIERS =====

  /// Sélectionne un fichier.
  Future<PickedFile?> pickFile({
    FilePickerType type = FilePickerType.any,
    List<String>? allowedExtensions,
  }) async {
    FileType fileType;
    List<String>? extensions;

    switch (type) {
      case FilePickerType.image:
        fileType = FileType.image;
        break;
      case FilePickerType.pdf:
        fileType = FileType.custom;
        extensions = ['pdf'];
        break;
      case FilePickerType.document:
        fileType = FileType.custom;
        extensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];
        break;
      case FilePickerType.any:
        fileType = allowedExtensions != null ? FileType.custom : FileType.any;
        extensions = allowedExtensions;
        break;
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: extensions,
    );

    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.first;
    if (platformFile.path == null) return null;

    final file = File(platformFile.path!);
    final mimeType = _getMimeType(platformFile.name);

    return PickedFile(
      file: file,
      fileName: platformFile.name,
      mimeType: mimeType,
      size: platformFile.size,
    );
  }

  /// Sélectionne plusieurs fichiers.
  Future<List<PickedFile>> pickMultipleFiles({
    FilePickerType type = FilePickerType.any,
    List<String>? allowedExtensions,
  }) async {
    FileType fileType;
    List<String>? extensions;

    switch (type) {
      case FilePickerType.image:
        fileType = FileType.image;
        break;
      case FilePickerType.pdf:
        fileType = FileType.custom;
        extensions = ['pdf'];
        break;
      case FilePickerType.document:
        fileType = FileType.custom;
        extensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];
        break;
      case FilePickerType.any:
        fileType = allowedExtensions != null ? FileType.custom : FileType.any;
        extensions = allowedExtensions;
        break;
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: extensions,
      allowMultiple: true,
    );

    if (result == null) return [];

    final results = <PickedFile>[];
    for (final platformFile in result.files) {
      if (platformFile.path == null) continue;

      final file = File(platformFile.path!);
      final mimeType = _getMimeType(platformFile.name);

      results.add(PickedFile(
        file: file,
        fileName: platformFile.name,
        mimeType: mimeType,
        size: platformFile.size,
      ));
    }
    return results;
  }

  /// Sélectionne un PDF.
  Future<PickedFile?> pickPdf() => pickFile(type: FilePickerType.pdf);

  /// Sélectionne un document (PDF, Word, Excel).
  Future<PickedFile?> pickDocument() => pickFile(type: FilePickerType.document);

  // ===== UTILS =====

  String _getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return _mimeTypes[ext] ?? 'application/octet-stream';
  }

  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'json': 'application/json',
    'xml': 'application/xml',
    'zip': 'application/zip',
    'mp3': 'audio/mpeg',
    'mp4': 'video/mp4',
  };
}
