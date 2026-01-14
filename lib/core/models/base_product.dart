import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'base_model.dart';

/// Modèle produit/service de base.
///
/// Représente un produit ou service avec prix HT et TVA.
/// Adapté aux normes françaises de facturation.
class BaseProduct extends Equatable implements BaseModel {
  @override
  final String id;

  /// ID de l'utilisateur propriétaire.
  final String userId;

  /// Nom du produit/service.
  final String name;

  /// Description.
  final String? description;

  /// Prix hors taxes.
  final double priceHT;

  /// Taux de TVA (ex: 20.0 pour 20%).
  final double tva;

  /// Unité de mesure (ex: 'unité', 'heure', 'jour', 'm²').
  final String unit;

  /// Indique si le produit est actif.
  final bool isActive;

  /// Exonéré de TVA (micro-entreprise, etc.).
  final bool tvaExempt;

  /// Date de création.
  final DateTime? createdAt;

  /// Dernière mise à jour.
  final DateTime? updatedAt;

  const BaseProduct({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.priceHT,
    this.tva = 20.0,
    this.unit = 'unité',
    this.isActive = true,
    this.tvaExempt = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Taux de TVA français standard.
  static const double tvaNormale = 20.0;
  static const double tvaIntermediaire = 10.0;
  static const double tvaReduite = 5.5;
  static const double tvaSuperReduite = 2.1;
  static const double tvaExoneree = 0.0;

  /// Crée un BaseProduct depuis une Map Firestore.
  factory BaseProduct.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BaseProduct(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      priceHT: (map['priceHT'] ?? map['price'] ?? 0).toDouble(),
      tva: (map['tva'] ?? 20.0).toDouble(),
      unit: map['unit'] ?? 'unité',
      isActive: map['isActive'] ?? true,
      tvaExempt: map['tvaExempt'] ?? false,
      createdAt: FirestoreModel.dateTimeFromFirestore(map['createdAt']),
      updatedAt: FirestoreModel.dateTimeFromFirestore(map['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'priceHT': priceHT,
      'tva': tva,
      'unit': unit,
      'isActive': isActive,
      'tvaExempt': tvaExempt,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  BaseProduct copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? priceHT,
    double? tva,
    String? unit,
    bool? isActive,
    bool? tvaExempt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BaseProduct(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceHT: priceHT ?? this.priceHT,
      tva: tva ?? this.tva,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      tvaExempt: tvaExempt ?? this.tvaExempt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Prix TTC calculé.
  double get priceTTC {
    if (tvaExempt) return priceHT;
    return priceHT * (1 + tva / 100);
  }

  /// Montant de TVA.
  double get tvaAmount {
    if (tvaExempt) return 0;
    return priceHT * (tva / 100);
  }

  /// Prix HT formaté en euros.
  String get formattedPriceHT {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(priceHT);
  }

  /// Prix TTC formaté en euros.
  String get formattedPriceTTC {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(priceTTC);
  }

  /// Label du taux de TVA.
  String get tvaLabel {
    if (tvaExempt) return 'Exonéré';
    return '${tva.toStringAsFixed(tva.truncateToDouble() == tva ? 0 : 1)}%';
  }

  @override
  List<Object?> get props => [id, userId, name, priceHT, tva];
}
