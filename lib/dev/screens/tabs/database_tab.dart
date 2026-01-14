import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/base_master_dev_service.dart';

/// Tab Database Explorer - parcourt les collections Firestore.
class DatabaseTab extends StatefulWidget {
  final BaseMasterDevService masterDevService;

  /// Icônes personnalisées par collection (optionnel).
  final Map<String, IconData>? collectionIcons;

  const DatabaseTab({
    super.key,
    required this.masterDevService,
    this.collectionIcons,
  });

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final _searchController = TextEditingController();

  String? _selectedCollection;
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic>? _selectedDocument;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection(String collection) async {
    setState(() {
      _isLoading = true;
      _selectedCollection = collection;
      _selectedDocument = null;
    });

    final docs =
        await widget.masterDevService.getCollectionDocuments(collection);

    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _searchDocument() async {
    final docId = _searchController.text.trim();
    if (docId.isEmpty || _selectedCollection == null) return;

    setState(() => _isLoading = true);

    final doc = await widget.masterDevService
        .getDocument(_selectedCollection!, docId);

    setState(() {
      _isLoading = false;
      if (doc != null) {
        _selectedDocument = doc;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document "$docId" non trouvé')),
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copié dans le presse-papier'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Collections sidebar
        SizedBox(
          width: 180,
          child: _buildCollectionsList(),
        ),
        const VerticalDivider(width: 1),

        // Documents list or detail view
        Expanded(
          child: _selectedDocument != null
              ? _buildDocumentDetail()
              : _buildDocumentsList(),
        ),
      ],
    );
  }

  Widget _buildCollectionsList() {
    final collections = widget.masterDevService.mainCollections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Collections',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              final isSelected = collection == _selectedCollection;

              return ListTile(
                dense: true,
                selected: isSelected,
                leading: Icon(
                  _getCollectionIcon(collection),
                  size: 16,
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                title: Text(collection, style: const TextStyle(fontSize: 13)),
                onTap: () => _loadCollection(collection),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    if (_selectedCollection == null) {
      return const Center(child: Text('Sélectionnez une collection'));
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par ID de document...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _searchDocument(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search, size: 18),
                onPressed: _searchDocument,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Documents list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? Center(
                      child: Text('Aucun document dans $_selectedCollection'))
                  : ListView.separated(
                      itemCount: _documents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        final docId = doc['_documentId'] ?? 'unknown';

                        return ListTile(
                          dense: true,
                          title: Text(docId,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12)),
                          subtitle: Text(_getDocumentPreview(doc),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing:
                              const Icon(Icons.chevron_right, size: 16),
                          onTap: () =>
                              setState(() => _selectedDocument = doc),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDocumentDetail() {
    final doc = _selectedDocument!;
    final docId = doc['_documentId'] ?? 'unknown';
    final jsonString = const JsonEncoder.withIndent('  ').convert(doc);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: () => setState(() => _selectedDocument = null),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docId,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold)),
                    Text('$_selectedCollection',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(jsonString),
                tooltip: 'Copier JSON',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // JSON view
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCollectionIcon(String collection) {
    // Check custom icons first
    if (widget.collectionIcons?.containsKey(collection) == true) {
      return widget.collectionIcons![collection]!;
    }

    // Default icons
    switch (collection) {
      case 'users':
        return Icons.people;
      case 'clients':
        return Icons.business;
      case 'products':
        return Icons.inventory_2;
      case 'quotes':
        return Icons.description;
      case 'invoices':
        return Icons.receipt_long;
      case 'missions':
        return Icons.assignment;
      case 'conversations':
        return Icons.chat;
      case 'notifications':
      case 'user_notifications':
        return Icons.notifications;
      case 'invitation_codes':
        return Icons.qr_code;
      case 'app_config':
        return Icons.settings;
      case 'payment_transactions':
        return Icons.payment;
      default:
        return Icons.folder;
    }
  }

  String _getDocumentPreview(Map<String, dynamic> doc) {
    final preview = <String>[];
    if (doc['email'] != null) preview.add(doc['email']);
    if (doc['name'] != null) preview.add(doc['name']);
    if (doc['title'] != null) preview.add(doc['title']);
    if (doc['status'] != null) preview.add(doc['status']);
    return preview.isEmpty ? '...' : preview.join(' • ');
  }
}
