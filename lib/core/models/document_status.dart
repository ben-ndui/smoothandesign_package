/// Status générique pour documents (devis, factures, etc.).
enum DocumentStatus {
  draft,
  sent,
  accepted,
  rejected,
  expired,
  paid,
  cancelled,
  pending,
  inProgress,
  completed;

  /// Nom d'affichage en français.
  String get displayName {
    switch (this) {
      case DocumentStatus.draft:
        return 'Brouillon';
      case DocumentStatus.sent:
        return 'Envoyé';
      case DocumentStatus.accepted:
        return 'Accepté';
      case DocumentStatus.rejected:
        return 'Refusé';
      case DocumentStatus.expired:
        return 'Expiré';
      case DocumentStatus.paid:
        return 'Payé';
      case DocumentStatus.cancelled:
        return 'Annulé';
      case DocumentStatus.pending:
        return 'En attente';
      case DocumentStatus.inProgress:
        return 'En cours';
      case DocumentStatus.completed:
        return 'Terminé';
    }
  }

  /// Couleur hex suggérée pour le status.
  String get colorHex {
    switch (this) {
      case DocumentStatus.draft:
        return '9CA3AF'; // Gray
      case DocumentStatus.sent:
        return '3B82F6'; // Blue
      case DocumentStatus.accepted:
        return '10B981'; // Green
      case DocumentStatus.rejected:
        return 'EF4444'; // Red
      case DocumentStatus.expired:
        return 'F59E0B'; // Amber
      case DocumentStatus.paid:
        return '10B981'; // Green
      case DocumentStatus.cancelled:
        return '6B7280'; // Gray dark
      case DocumentStatus.pending:
        return 'F59E0B'; // Amber
      case DocumentStatus.inProgress:
        return '3B82F6'; // Blue
      case DocumentStatus.completed:
        return '10B981'; // Green
    }
  }

  /// Indique si le document peut être modifié.
  bool get isEditable {
    return this == DocumentStatus.draft;
  }

  /// Indique si le document est finalisé.
  bool get isFinal {
    return this == DocumentStatus.paid ||
        this == DocumentStatus.cancelled ||
        this == DocumentStatus.completed;
  }

  /// Crée depuis une chaîne.
  static DocumentStatus fromString(String? value) {
    return DocumentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentStatus.draft,
    );
  }
}

/// Type de document.
enum DocumentType {
  quote,
  invoice,
  depositInvoice,
  balanceInvoice,
  creditNote;

  String get displayName {
    switch (this) {
      case DocumentType.quote:
        return 'Devis';
      case DocumentType.invoice:
        return 'Facture';
      case DocumentType.depositInvoice:
        return 'Facture d\'acompte';
      case DocumentType.balanceInvoice:
        return 'Facture de solde';
      case DocumentType.creditNote:
        return 'Avoir';
    }
  }

  String get prefix {
    switch (this) {
      case DocumentType.quote:
        return 'DEV';
      case DocumentType.invoice:
        return 'FAC';
      case DocumentType.depositInvoice:
        return 'FAC-AC';
      case DocumentType.balanceInvoice:
        return 'FAC-SOL';
      case DocumentType.creditNote:
        return 'AV';
    }
  }

  static DocumentType fromString(String? value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.invoice,
    );
  }
}
