import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Configuration d'une migration
class MigrationConfig {
  final String id;
  final String name;
  final String description;
  final String url;
  final IconData icon;

  const MigrationConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    this.icon = Icons.sync,
  });
}

/// Tab des migrations - permet d'exécuter les scripts de migration.
class MigrationsTab extends StatefulWidget {
  /// Liste des migrations disponibles
  final List<MigrationConfig> migrations;

  const MigrationsTab({
    super.key,
    required this.migrations,
  });

  @override
  State<MigrationsTab> createState() => _MigrationsTabState();
}

class _MigrationsTabState extends State<MigrationsTab> {
  final Map<String, bool> _runningMigrations = {};
  final Map<String, MigrationResult?> _results = {};

  Future<void> _runMigration(MigrationConfig migration) async {
    setState(() {
      _runningMigrations[migration.id] = true;
      _results[migration.id] = null;
    });

    try {
      final response = await http.get(Uri.parse(migration.url));
      final data = jsonDecode(response.body);

      setState(() {
        _results[migration.id] = MigrationResult(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Terminé',
          migratedCount: data['migratedCount'] ?? 0,
          skippedCount: data['skippedCount'] ?? 0,
          total: data['totalUsers'] ?? data['totalClients'] ?? 0,
        );
      });
    } catch (e) {
      setState(() {
        _results[migration.id] = MigrationResult(
          success: false,
          message: 'Erreur: $e',
          migratedCount: 0,
          skippedCount: 0,
          total: 0,
        );
      });
    } finally {
      setState(() {
        _runningMigrations[migration.id] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.sync, size: 18),
              const SizedBox(width: 8),
              Text(
                '${widget.migrations.length} migrations disponibles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Migrations list
        Expanded(
          child: widget.migrations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.migrations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildMigrationCard(widget.migrations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_disabled, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune migration configurée',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationCard(MigrationConfig migration) {
    final isRunning = _runningMigrations[migration.id] ?? false;
    final result = _results[migration.id];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(migration.icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        migration.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        migration.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isRunning ? null : () => _runMigration(migration),
                  icon: isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(isRunning ? 'En cours...' : 'Exécuter'),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildResultWidget(result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget(MigrationResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                size: 18,
                color: result.success ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: result.success ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          if (result.success) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip(
                  'Migrés',
                  result.migratedCount.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Ignorés',
                  result.skippedCount.toString(),
                  Colors.grey,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Total',
                  result.total.toString(),
                  Colors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MigrationResult {
  final bool success;
  final String message;
  final int migratedCount;
  final int skippedCount;
  final int total;

  const MigrationResult({
    required this.success,
    required this.message,
    required this.migratedCount,
    required this.skippedCount,
    required this.total,
  });
}
