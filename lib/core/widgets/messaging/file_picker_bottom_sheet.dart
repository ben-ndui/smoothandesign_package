import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Résultat de la sélection de fichier.
class FilePickerResult {
  final File file;
  final String fileName;
  final String mimeType;

  const FilePickerResult({
    required this.file,
    required this.fileName,
    required this.mimeType,
  });

  bool get isImage => mimeType.startsWith('image/');
}

/// Bottom sheet pour sélectionner des fichiers ou prendre des photos.
class FilePickerBottomSheet extends StatelessWidget {
  final void Function(FilePickerResult result) onFilePicked;

  const FilePickerBottomSheet({super.key, required this.onFilePicked});

  /// Affiche le bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required void Function(FilePickerResult result) onFilePicked,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => FilePickerBottomSheet(onFilePicked: onFilePicked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: FontAwesomeIcons.camera,
              label: 'Prendre une photo',
              onTap: () => _pickFromCamera(context),
            ),
            _buildOption(
              context,
              icon: FontAwesomeIcons.image,
              label: 'Galerie photos',
              onTap: () => _pickFromGallery(context),
            ),
            _buildOption(
              context,
              icon: FontAwesomeIcons.file,
              label: 'Document',
              onTap: () => _pickDocument(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FaIcon(icon, size: 18, color: theme.colorScheme.primary),
        ),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      onTap: onTap,
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _handleResult(File(image.path), image.name, 'image/jpeg');
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final mimeType = _getMimeType(image.name);
      _handleResult(File(image.path), image.name, mimeType);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final mimeType = _getMimeType(file.name);
      _handleResult(File(file.path!), file.name, mimeType);
    }
  }

  void _handleResult(File file, String name, String mimeType) {
    onFilePicked(FilePickerResult(
      file: file,
      fileName: name,
      mimeType: mimeType,
    ));
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
      default:
        return 'application/octet-stream';
    }
  }
}
