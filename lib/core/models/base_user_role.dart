/// Rôles utilisateur de base.
///
/// Étendre avec des valeurs supplémentaires si nécessaire.
/// Ce sont les rôles les plus communs pour une application multi-tenant.
enum BaseUserRole {
  /// Utilisateur standard.
  user,

  /// Administrateur avec tous les droits.
  admin,

  /// Travailleur/Employé avec droits limités.
  worker,

  /// Client externe avec accès restreint.
  client,

  /// Super administrateur (accès système).
  superAdmin,
}

/// Extension pour BaseUserRole avec helpers.
extension BaseUserRoleExtension on BaseUserRole {
  /// Label français du rôle.
  String get label {
    switch (this) {
      case BaseUserRole.user:
        return 'Utilisateur';
      case BaseUserRole.admin:
        return 'Administrateur';
      case BaseUserRole.worker:
        return 'Employé';
      case BaseUserRole.client:
        return 'Client';
      case BaseUserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Description du rôle.
  String get description {
    switch (this) {
      case BaseUserRole.user:
        return 'Accès de base à l\'application';
      case BaseUserRole.admin:
        return 'Gestion complète de l\'espace de travail';
      case BaseUserRole.worker:
        return 'Exécution des tâches assignées';
      case BaseUserRole.client:
        return 'Accès client au portail';
      case BaseUserRole.superAdmin:
        return 'Administration système globale';
    }
  }

  /// Vérifie si c'est un rôle administrateur.
  bool get isAdminRole => this == BaseUserRole.admin || this == BaseUserRole.superAdmin;

  /// Vérifie si c'est un rôle interne (pas client).
  bool get isInternalRole => this != BaseUserRole.client;

  /// Convertit en chaîne pour Firestore.
  String toFirestore() => name;

  /// Crée depuis une chaîne Firestore.
  static BaseUserRole fromString(String? value) {
    if (value == null) return BaseUserRole.user;

    return BaseUserRole.values.firstWhere(
      (role) => role.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BaseUserRole.user,
    );
  }
}
