import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Configuration générique d'un tier d'abonnement.
///
/// Les features et limites sont flexibles via Maps, permettant
/// à chaque app de définir ses propres fonctionnalités.
///
/// Usage:
/// ```dart
/// final proTier = SubscriptionTier(
///   id: 'pro',
///   name: 'Pro',
///   priceMonthly: 19.0,
///   priceYearly: 190.0,
///   limits: {
///     'maxUsers': 10,
///     'maxProjects': -1, // -1 = illimité
///   },
///   features: {
///     'hasAnalytics': true,
///     'hasPrioritySupport': true,
///   },
/// );
///
/// // Vérifier une limite
/// final canAdd = tier.checkLimit('maxUsers', currentCount: 5);
///
/// // Vérifier une feature
/// final hasFeature = tier.hasFeature('hasAnalytics');
/// ```
class SubscriptionTier extends Equatable {
  final String id;
  final String name;
  final String description;
  final double priceMonthly;
  final double priceYearly;

  /// Limites numériques (-1 = illimité).
  /// Ex: {'maxUsers': 10, 'maxProjects': -1}
  final Map<String, int> limits;

  /// Features boolean/string.
  /// Ex: {'hasAnalytics': true, 'theme': 'premium'}
  final Map<String, dynamic> features;

  /// Métadonnées
  final bool isActive;
  final int sortOrder;
  final DateTime? updatedAt;

  const SubscriptionTier({
    required this.id,
    required this.name,
    this.description = '',
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.limits = const {},
    this.features = const {},
    this.isActive = true,
    this.sortOrder = 0,
    this.updatedAt,
  });

  /// Vérifie si une limite est illimitée.
  bool isUnlimited(String limitKey) => limits[limitKey] == -1;

  /// Vérifie si le tier est gratuit.
  bool get isFree => priceMonthly == 0 && priceYearly == 0;

  /// Récupère une limite (-1 si non définie = illimité).
  int getLimit(String key) => limits[key] ?? -1;

  /// Vérifie si une action est permise selon une limite.
  /// Retourne true si illimité ou currentCount < limite.
  bool checkLimit(String limitKey, {required int currentCount}) {
    final limit = getLimit(limitKey);
    if (limit == -1) return true;
    return currentCount < limit;
  }

  /// Vérifie si une feature est activée.
  bool hasFeature(String key) {
    final value = features[key];
    if (value == null) return false;
    if (value is bool) return value;
    return true; // Si présent et non-null, considéré comme actif
  }

  /// Récupère la valeur d'une feature.
  T? getFeature<T>(String key) => features[key] as T?;

  /// Prix annuel avec réduction (si applicable).
  double get yearlyDiscount {
    if (priceMonthly == 0) return 0;
    final fullYearPrice = priceMonthly * 12;
    return fullYearPrice - priceYearly;
  }

  /// Nombre de mois gratuits avec l'abonnement annuel.
  int get freeMonthsWithYearly {
    if (priceMonthly == 0) return 0;
    return (yearlyDiscount / priceMonthly).round();
  }

  /// Pourcentage de réduction annuelle.
  double get yearlyDiscountPercent {
    if (priceMonthly == 0) return 0;
    final fullYearPrice = priceMonthly * 12;
    return ((fullYearPrice - priceYearly) / fullYearPrice) * 100;
  }

  factory SubscriptionTier.fromMap(Map<String, dynamic> map, {String? id}) {
    return SubscriptionTier(
      id: id ?? map['id'] ?? 'unknown',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      priceMonthly: (map['priceMonthly'] as num?)?.toDouble() ?? 0,
      priceYearly: (map['priceYearly'] as num?)?.toDouble() ?? 0,
      limits: _parseIntMap(map['limits']),
      features: (map['features'] as Map<String, dynamic>?) ?? {},
      isActive: map['isActive'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'priceMonthly': priceMonthly,
        'priceYearly': priceYearly,
        'limits': limits,
        'features': features,
        'isActive': isActive,
        'sortOrder': sortOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  SubscriptionTier copyWith({
    String? id,
    String? name,
    String? description,
    double? priceMonthly,
    double? priceYearly,
    Map<String, int>? limits,
    Map<String, dynamic>? features,
    bool? isActive,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return SubscriptionTier(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      priceYearly: priceYearly ?? this.priceYearly,
      limits: limits ?? this.limits,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ajoute ou met à jour une limite.
  SubscriptionTier withLimit(String key, int value) {
    return copyWith(limits: {...limits, key: value});
  }

  /// Ajoute ou met à jour une feature.
  SubscriptionTier withFeature(String key, dynamic value) {
    return copyWith(features: {...features, key: value});
  }

  static Map<String, int> _parseIntMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    }
    return {};
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        priceMonthly,
        priceYearly,
        limits,
        features,
        isActive,
        sortOrder,
        updatedAt,
      ];
}
