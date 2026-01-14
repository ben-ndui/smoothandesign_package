import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'base_model.dart';

/// Statut de document générique.
enum BaseDocumentStatus {
  draft,
  sent,
  accepted,
  rejected,
  paid,
  cancelled,
  expired,
}

/// Extension pour BaseDocumentStatus.
extension BaseDocumentStatusExtension on BaseDocumentStatus {
  String get label {
    switch (this) {
      case BaseDocumentStatus.draft:
        return 'Brouillon';
      case BaseDocumentStatus.sent:
        return 'Envoyé';
      case BaseDocumentStatus.accepted:
        return 'Accepté';
      case BaseDocumentStatus.rejected:
        return 'Refusé';
      case BaseDocumentStatus.paid:
        return 'Payé';
      case BaseDocumentStatus.cancelled:
        return 'Annulé';
      case BaseDocumentStatus.expired:
        return 'Expiré';
    }
  }

  static BaseDocumentStatus fromString(String? value) {
    if (value == null) return BaseDocumentStatus.draft;
    return BaseDocumentStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => BaseDocumentStatus.draft,
    );
  }
}

/// Ligne de document (produit/service).
class BaseLineItem extends Equatable {
  final String? productId;
  final String productName;
  final String? description;
  final double quantity;
  final double priceHT;
  final double tva;
  final String unit;

  const BaseLineItem({
    this.productId,
    required this.productName,
    this.description,
    required this.quantity,
    required this.priceHT,
    this.tva = 20.0,
    this.unit = 'unité',
  });

  factory BaseLineItem.fromMap(Map<String, dynamic> map) {
    return BaseLineItem(
      productId: map['productId'],
      productName: map['productName'] ?? map['name'] ?? '',
      description: map['description'],
      quantity: (map['quantity'] ?? 1).toDouble(),
      priceHT: (map['priceHT'] ?? map['price'] ?? 0).toDouble(),
      tva: (map['tva'] ?? 20.0).toDouble(),
      unit: map['unit'] ?? 'unité',
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'description': description,
    'quantity': quantity,
    'priceHT': priceHT,
    'tva': tva,
    'unit': unit,
  };

  /// Total HT de la ligne.
  double get totalHT => quantity * priceHT;

  /// Total TVA de la ligne.
  double get totalTVA => totalHT * (tva / 100);

  /// Total TTC de la ligne.
  double get totalTTC => totalHT + totalTVA;

  BaseLineItem copyWith({
    String? productId,
    String? productName,
    String? description,
    double? quantity,
    double? priceHT,
    double? tva,
    String? unit,
  }) {
    return BaseLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      priceHT: priceHT ?? this.priceHT,
      tva: tva ?? this.tva,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [productId, productName, quantity, priceHT, tva];
}

/// Modèle document de base (devis/facture).
///
/// Contient la logique commune aux devis et factures.
/// Étendre pour créer des types de documents spécifiques.
class BaseDocument extends Equatable implements BaseModel {
  @override
  final String id;

  /// ID de l'utilisateur propriétaire.
  final String userId;

  /// ID du client.
  final String clientId;

  /// Nom du client (dénormalisé).
  final String? clientName;

  /// Titre du document.
  final String? title;

  /// Description.
  final String? description;

  /// Lignes du document.
  final List<BaseLineItem> items;

  /// Statut du document.
  final BaseDocumentStatus status;

  /// Notes additionnelles.
  final String? notes;

  /// URL du PDF généré.
  final String? pdfUrl;

  /// Date de création.
  final DateTime? createdAt;

  /// Dernière mise à jour.
  final DateTime? updatedAt;

  const BaseDocument({
    required this.id,
    required this.userId,
    required this.clientId,
    this.clientName,
    this.title,
    this.description,
    this.items = const [],
    this.status = BaseDocumentStatus.draft,
    this.notes,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory BaseDocument.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BaseDocument(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'],
      title: map['title'],
      description: map['description'],
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => BaseLineItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      status: BaseDocumentStatusExtension.fromString(map['status']),
      notes: map['notes'],
      pdfUrl: map['pdfUrl'],
      createdAt: FirestoreModel.dateTimeFromFirestore(map['createdAt']),
      updatedAt: FirestoreModel.dateTimeFromFirestore(map['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'notes': notes,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  BaseDocument copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? clientName,
    String? title,
    String? description,
    List<BaseLineItem>? items,
    BaseDocumentStatus? status,
    String? notes,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BaseDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===== Calculs =====

  /// Total HT.
  double get totalHT => items.fold(0, (sum, item) => sum + item.totalHT);

  /// Total TVA.
  double get totalTVA => items.fold(0, (sum, item) => sum + item.totalTVA);

  /// Total TTC.
  double get totalTTC => totalHT + totalTVA;

  /// Détail TVA par taux.
  Map<double, double> get tvaBreakdown {
    final breakdown = <double, double>{};
    for (final item in items) {
      breakdown[item.tva] = (breakdown[item.tva] ?? 0) + item.totalTVA;
    }
    return breakdown;
  }

  // ===== Formatage =====

  String get formattedTotalHT =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalHT);

  String get formattedTotalTVA =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalTVA);

  String get formattedTotalTTC =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalTTC);

  // ===== Helpers =====

  bool get isDraft => status == BaseDocumentStatus.draft;
  bool get isSent => status == BaseDocumentStatus.sent;
  bool get isAccepted => status == BaseDocumentStatus.accepted;
  bool get isPaid => status == BaseDocumentStatus.paid;
  bool get isCancelled => status == BaseDocumentStatus.cancelled;

  bool get canEdit => isDraft;
  bool get canSend => isDraft || status == BaseDocumentStatus.rejected;
  bool get canCancel => !isCancelled && !isPaid;

  @override
  List<Object?> get props => [id, userId, clientId, status, totalTTC];
}
