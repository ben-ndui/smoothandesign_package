import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Modèle générique représentant un favori.
///
/// Usage:
/// ```dart
/// // Créer un favori
/// final favorite = Favorite(
///   id: 'fav123',
///   userId: 'user456',
///   targetId: 'item789',
///   type: 'product',
///   createdAt: DateTime.now(),
///   targetName: 'Mon Produit',
/// );
///
/// // Depuis Firestore
/// final fav = Favorite.fromMap(doc.data(), doc.id);
/// ```
class Favorite extends Equatable {
  final String id;
  final String userId;
  final String targetId;

  /// Type de favori (string pour flexibilité maximale).
  /// Ex: 'studio', 'product', 'article', 'user', etc.
  final String type;

  final DateTime createdAt;

  /// Données dénormalisées pour l'affichage.
  final String? targetName;
  final String? targetPhotoUrl;
  final String? targetSubtitle;

  /// Données additionnelles (flexible).
  final Map<String, dynamic>? metadata;

  const Favorite({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.type,
    required this.createdAt,
    this.targetName,
    this.targetPhotoUrl,
    this.targetSubtitle,
    this.metadata,
  });

  factory Favorite.fromMap(Map<String, dynamic> map, String id) {
    return Favorite(
      id: id,
      userId: map['userId'] ?? '',
      targetId: map['targetId'] ?? '',
      type: map['type'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      targetName: map['targetName'],
      targetPhotoUrl: map['targetPhotoUrl'],
      targetSubtitle: map['targetSubtitle'] ?? map['targetAddress'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'targetId': targetId,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        if (targetName != null) 'targetName': targetName,
        if (targetPhotoUrl != null) 'targetPhotoUrl': targetPhotoUrl,
        if (targetSubtitle != null) 'targetSubtitle': targetSubtitle,
        if (metadata != null) 'metadata': metadata,
      };

  Favorite copyWith({
    String? id,
    String? userId,
    String? targetId,
    String? type,
    DateTime? createdAt,
    String? targetName,
    String? targetPhotoUrl,
    String? targetSubtitle,
    Map<String, dynamic>? metadata,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetName: targetName ?? this.targetName,
      targetPhotoUrl: targetPhotoUrl ?? this.targetPhotoUrl,
      targetSubtitle: targetSubtitle ?? this.targetSubtitle,
      metadata: metadata ?? this.metadata,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  List<Object?> get props => [id, userId, targetId, type];
}
