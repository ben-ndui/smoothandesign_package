import 'package:flutter/material.dart';

import '../../../core/services/base_master_dev_service.dart';

/// Tab des feature flags - gère les flags globaux de l'app.
class FeatureFlagsTab extends StatefulWidget {
  final BaseMasterDevService masterDevService;

  const FeatureFlagsTab({
    super.key,
    required this.masterDevService,
  });

  @override
  State<FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends State<FeatureFlagsTab> {
  final _newFlagController = TextEditingController();

  @override
  void dispose() {
    _newFlagController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlag(String key, bool currentValue) async {
    await widget.masterDevService.setFeatureFlag(key, !currentValue);
  }

  Future<void> _deleteFlag(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le flag'),
        content: Text('Supprimer "$key" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.masterDevService.deleteFeatureFlag(key);
    }
  }

  Future<void> _addNewFlag() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un Feature Flag'),
        content: TextField(
          controller: _newFlagController,
          decoration:
              const InputDecoration(hintText: 'Nom du flag (camelCase)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _newFlagController.text.trim());
              _newFlagController.clear();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await widget.masterDevService.setFeatureFlag(name, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: widget.masterDevService.streamFeatureFlags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final flags = snapshot.data ?? {};
        final sortedKeys = flags.keys.toList()..sort();

        return Column(
          children: [
            // Header with add button
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('${flags.length} flags',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _addNewFlag,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Flags list
            Expanded(
              child: flags.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: sortedKeys.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final key = sortedKeys[index];
                        final value = flags[key]!;
                        return _buildFlagTile(key, value);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun feature flag',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addNewFlag,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Ajouter votre premier flag'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagTile(String key, bool value) {
    final isMaintenanceMode = key == 'maintenanceMode';

    return ListTile(
      leading: Icon(
        isMaintenanceMode ? Icons.build : Icons.toggle_on,
        size: 20,
        color: value ? Colors.green : Colors.grey,
      ),
      title: Text(key,
          style: const TextStyle(
              fontFamily: 'monospace', fontWeight: FontWeight.w600)),
      subtitle: Text(
        value ? 'Activé' : 'Désactivé',
        style: TextStyle(color: value ? Colors.green : Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: value,
            onChanged: (_) => _toggleFlag(key, value),
            activeTrackColor: isMaintenanceMode ? Colors.orange : Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _deleteFlag(key),
            color: Colors.red[300],
          ),
        ],
      ),
    );
  }
}
