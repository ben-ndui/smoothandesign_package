import 'package:flutter/material.dart';

import '../../../core/models/base_user.dart';
import '../../../core/models/base_user_role.dart';
import '../../../core/services/base_master_dev_service.dart';

/// Tab d'impersonation - permet au masterDev d'agir comme n'importe quel user.
///
/// Note: L'impersonation via AuthBloc a été désactivée car elle nécessite
/// que l'AuthBloc soit fourni dans le contexte. Utiliser le service directement.
class ImpersonationTab extends StatefulWidget {
  final BaseMasterDevService masterDevService;

  /// Callback optionnel pour convertir les users (si modèle personnalisé).
  final Widget Function(BaseUser user, bool isImpersonating)?
      userTileBuilder;

  /// Callback appelé quand l'utilisateur veut impersonner quelqu'un.
  final void Function(BaseUser user)? onImpersonate;

  /// Callback appelé quand l'utilisateur veut arrêter l'impersonation.
  final void Function()? onStopImpersonation;

  /// Utilisateur actuellement impersonné (null si pas d'impersonation).
  final BaseUser? impersonatedUser;

  const ImpersonationTab({
    super.key,
    required this.masterDevService,
    this.userTileBuilder,
    this.onImpersonate,
    this.onStopImpersonation,
    this.impersonatedUser,
  });

  @override
  State<ImpersonationTab> createState() => _ImpersonationTabState();
}

class _ImpersonationTabState extends State<ImpersonationTab> {
  final _searchController = TextEditingController();

  List<BaseUser> _users = [];
  List<BaseUser> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await widget.masterDevService.getAllUsers();
    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }
    final queryLower = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.email.toLowerCase().contains(queryLower) ||
            (user.name?.toLowerCase().contains(queryLower) ?? false) ||
            user.role.name.toLowerCase().contains(queryLower);
      }).toList();
    });
  }

  void _impersonateUser(BaseUser user) {
    widget.onImpersonate?.call(user);
  }

  void _stopImpersonation() {
    widget.onStopImpersonation?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isImpersonating = widget.impersonatedUser != null;

    return Column(
      children: [
        // Impersonation banner (if active)
        if (isImpersonating) _buildImpersonationBanner(widget.impersonatedUser!),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par email, nom ou rôle...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers('');
                      },
                    )
                  : null,
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: _filterUsers,
          ),
        ),

        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text(
                '${_filteredUsers.length} utilisateurs',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadUsers,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
        ),

        // Users list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(child: Text('Aucun utilisateur trouvé'))
                  : ListView.separated(
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserTile(user, isImpersonating);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildImpersonationBanner(BaseUser impersonatedUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode impersonation',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  '${impersonatedUser.fullName} (${impersonatedUser.email})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: _stopImpersonation,
            style:
                FilledButton.styleFrom(backgroundColor: Colors.orange.shade200),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BaseUser user, bool isImpersonating) {
    final isCurrentlyImpersonated =
        isImpersonating && widget.impersonatedUser?.uid == user.uid;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: TextStyle(
              color: _getRoleColor(user.role), fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Flexible(
              child:
                  Text(user.fullName, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.role.name,
              style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
      trailing: isCurrentlyImpersonated
          ? const Chip(
              label: Text('Actif',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.orange,
            )
          : IconButton(
              icon: const Icon(Icons.login, size: 18),
              onPressed: () => _impersonateUser(user),
              tooltip: 'Impersonner ${user.fullName}',
            ),
    );
  }

  Color _getRoleColor(BaseUserRole role) {
    switch (role) {
      case BaseUserRole.superAdmin:
        return Colors.purple;
      case BaseUserRole.admin:
        return Colors.blue;
      case BaseUserRole.worker:
        return Colors.green;
      case BaseUserRole.client:
        return Colors.teal;
      case BaseUserRole.user:
        return Colors.grey;
    }
  }
}
