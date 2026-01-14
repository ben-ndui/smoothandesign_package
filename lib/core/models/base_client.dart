import 'package:equatable/equatable.dart';
import 'base_model.dart';

/// Modèle client de base.
///
/// Représente un client/contact avec ses informations de base.
/// Étendre pour ajouter des champs spécifiques au projet.
class BaseClient extends Equatable implements BaseModel {
  @override
  final String id;

  /// ID de l'utilisateur propriétaire (admin).
  final String userId;

  /// Nom complet ou raison sociale.
  final String fullName;

  /// Nom de l'entreprise (optionnel).
  final String? company;

  /// Adresse email.
  final String? email;

  /// Numéro de téléphone.
  final String? phone;

  /// Adresse postale.
  final String? address;

  /// Ville.
  final String? city;

  /// Code postal.
  final String? zipCode;

  /// Pays.
  final String? country;

  /// Notes additionnelles.
  final String? notes;

  /// URL du logo/avatar.
  final String? logoUrl;

  /// Indique si le client est actif.
  final bool isActive;

  /// Date de création.
  final DateTime? createdAt;

  /// Dernière mise à jour.
  final DateTime? updatedAt;

  const BaseClient({
    required this.id,
    required this.userId,
    required this.fullName,
    this.company,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.zipCode,
    this.country,
    this.notes,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Crée un BaseClient depuis une Map Firestore.
  factory BaseClient.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BaseClient(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      company: map['company'],
      email: map['email'],
      phone: map['phone'] ?? map['phoneNumber'],
      address: map['address'],
      city: map['city'],
      zipCode: map['zipCode'] ?? map['postalCode'],
      country: map['country'] ?? 'France',
      notes: map['notes'],
      logoUrl: map['logoUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: FirestoreModel.dateTimeFromFirestore(map['createdAt']),
      updatedAt: FirestoreModel.dateTimeFromFirestore(map['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'zipCode': zipCode,
      'country': country,
      'notes': notes,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  BaseClient copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? zipCode,
    String? country,
    String? notes,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BaseClient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nom d'affichage (entreprise ou nom complet).
  String get displayName => company?.isNotEmpty == true ? company! : fullName;

  /// Adresse complète formatée.
  String get fullAddress {
    final parts = <String>[];
    if (address?.isNotEmpty == true) parts.add(address!);
    if (zipCode?.isNotEmpty == true || city?.isNotEmpty == true) {
      parts.add('${zipCode ?? ''} ${city ?? ''}'.trim());
    }
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }

  /// Initiales pour avatar.
  String get initials {
    final name = displayName;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  List<Object?> get props => [id, userId, fullName, email];
}
