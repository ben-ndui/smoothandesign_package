import 'package:flutter/material.dart';

import '../../core/services/base_master_dev_service.dart';
import 'tabs/database_tab.dart';
import 'tabs/feature_flags_tab.dart';
import 'tabs/impersonation_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/migrations_tab.dart';

/// Écran principal de la Dev Console.
///
/// Fournit 5 onglets: Impersonation, Database, Flags, Migrations, Logs.
/// ```dart
/// GoRoute(
///   path: '/dev-console',
///   builder: (context, state) => DevConsoleScreen(
///     masterDevService: getIt<MasterDevService>(),
///     migrations: [
///       MigrationConfig(
///         id: 'users_adminIds',
///         name: 'Users: adminId → adminIds',
///         description: 'Migration multi-équipe workers',
///         url: 'https://...',
///       ),
///     ],
///   ),
/// ),
/// ```
class DevConsoleScreen extends StatefulWidget {
  final BaseMasterDevService masterDevService;

  /// Titre personnalisé (défaut: "Dev Console").
  final String? title;

  /// Icônes personnalisées pour les collections dans Database tab.
  final Map<String, IconData>? collectionIcons;

  /// Liste des migrations disponibles.
  final List<MigrationConfig> migrations;

  const DevConsoleScreen({
    super.key,
    required this.masterDevService,
    this.title,
    this.collectionIcons,
    this.migrations = const [],
  });

  @override
  State<DevConsoleScreen> createState() => _DevConsoleScreenState();
}

class _DevConsoleScreenState extends State<DevConsoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(icon: Icon(Icons.person_outline), text: 'Impersonation'),
    Tab(icon: Icon(Icons.storage), text: 'Database'),
    Tab(icon: Icon(Icons.flag_outlined), text: 'Flags'),
    Tab(icon: Icon(Icons.sync), text: 'Migrations'),
    Tab(icon: Icon(Icons.article_outlined), text: 'Logs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Dev Console'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: 'Informations',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ImpersonationTab(masterDevService: widget.masterDevService),
          DatabaseTab(
            masterDevService: widget.masterDevService,
            collectionIcons: widget.collectionIcons,
          ),
          FeatureFlagsTab(masterDevService: widget.masterDevService),
          MigrationsTab(migrations: widget.migrations),
          const LogsTab(),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.developer_mode),
            SizedBox(width: 12),
            Text('Dev Console'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              title: 'Impersonation',
              desc: 'Se connecter en tant qu\'un autre utilisateur',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.storage,
              title: 'Database',
              desc: 'Explorer les collections Firestore',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.flag_outlined,
              title: 'Feature Flags',
              desc: 'Activer/désactiver des fonctionnalités',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.sync,
              title: 'Migrations',
              desc: 'Exécuter les scripts de migration de données',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.article_outlined,
              title: 'Logs',
              desc: 'Visualiser les logs en temps réel',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
