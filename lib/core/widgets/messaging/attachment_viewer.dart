import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/base_message.dart';

/// Viewer plein écran pour les pièces jointes (images et fichiers).
///
/// Affiche les images en mode zoom interactif et les fichiers avec aperçu.
class AttachmentViewer extends StatelessWidget {
  final MessageAttachment attachment;

  const AttachmentViewer({super.key, required this.attachment});

  /// Affiche le viewer en mode modal.
  static Future<void> show(BuildContext context, MessageAttachment attachment) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AttachmentViewer(attachment: attachment),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  bool get _isImage => attachment.isImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          attachment.fileName,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.download,
                color: Colors.white, size: 18),
            onPressed: () => _openUrl(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare,
                color: Colors.white, size: 18),
            onPressed: () => _openUrl(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: _isImage ? _buildImageViewer() : _buildFilePreview(context),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.network(
        attachment.url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation,
                color: Colors.white54, size: 48),
            SizedBox(height: 16),
            Text("Impossible de charger l'image",
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = attachment.fileName.split('.').last.toLowerCase();

    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: FaIcon(_getFileIcon(ext), size: 36, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            attachment.fileName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            attachment.formattedSize,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openUrl(context),
                icon: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 14),
                label: const Text('Ouvrir'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openUrl(context),
                icon: const FaIcon(FontAwesomeIcons.download, size: 14),
                label: const Text('Télécharger'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FaIconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return FontAwesomeIcons.filePdf;
      case 'doc':
      case 'docx':
        return FontAwesomeIcons.fileWord;
      case 'xls':
      case 'xlsx':
        return FontAwesomeIcons.fileExcel;
      case 'ppt':
      case 'pptx':
        return FontAwesomeIcons.filePowerpoint;
      case 'zip':
      case 'rar':
        return FontAwesomeIcons.fileZipper;
      case 'mp3':
      case 'm4a':
      case 'wav':
        return FontAwesomeIcons.fileAudio;
      case 'mp4':
      case 'mov':
      case 'avi':
        return FontAwesomeIcons.fileVideo;
      default:
        return FontAwesomeIcons.file;
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(attachment.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le fichier')),
        );
      }
    }
  }
}
