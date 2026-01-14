import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite.dart';
import '../models/smooth_response.dart';

/// Service générique pour gérer les favoris dans Firestore.
///
/// Usage:
/// ```dart
/// // Instanciation avec collection personnalisée
/// final favoriteService = BaseFavoriteService(
///   collectionName: 'myapp_favorites',
/// );
///
/// // Stream des favoris
/// favoriteService.streamFavorites(userId).listen((favorites) {
///   print('User has ${favorites.length} favorites');
/// });
///
/// // Toggle favori
/// final result = await favoriteService.toggleFavorite(
///   userId: userId,
///   targetId: productId,
///   type: 'product',
///   targetName: 'Mon Produit',
/// );
/// ```
class BaseFavoriteService {
  final FirebaseFirestore _firestore;
  final String collectionName;

  BaseFavoriteService({
    FirebaseFirestore? firestore,
    this.collectionName = 'favorites',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Stream des favoris d'un utilisateur.
  /// Le tri est fait côté client pour éviter les index composites.
  Stream<List<Favorite>> streamFavorites(String userId) {
    debugPrint('BaseFavoriteService.streamFavorites for userId: $userId');
    return _collection.where('userId', isEqualTo: userId).snapshots().map((s) {
      final favorites =
          s.docs.map((d) => Favorite.fromMap(d.data(), d.id)).toList();
      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return favorites;
    });
  }

  /// Stream des favoris par type.
  Stream<List<Favorite>> streamFavoritesByType(String userId, String type) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((s) {
      final favorites =
          s.docs.map((d) => Favorite.fromMap(d.data(), d.id)).toList();
      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return favorites;
    });
  }

  /// Vérifie si un élément est en favori.
  Future<bool> isFavorite(String userId, String targetId) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Stream pour vérifier si un élément est en favori (temps réel).
  Stream<bool> streamIsFavorite(String userId, String targetId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty);
  }

  /// Ajoute un favori.
  Future<SmoothResponse<Favorite>> addFavorite({
    required String userId,
    required String targetId,
    required String type,
    String? targetName,
    String? targetPhotoUrl,
    String? targetSubtitle,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Vérifier si déjà en favori
      final existing = await _collection
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return SmoothResponse.error(message: 'Already in favorites');
      }

      final data = {
        'userId': userId,
        'targetId': targetId,
        'type': type,
        'createdAt': DateTime.now().toIso8601String(),
        if (targetName != null) 'targetName': targetName,
        if (targetPhotoUrl != null) 'targetPhotoUrl': targetPhotoUrl,
        if (targetSubtitle != null) 'targetSubtitle': targetSubtitle,
        if (metadata != null) 'metadata': metadata,
      };

      final docRef = await _collection.add(data);
      final favorite = Favorite.fromMap(data, docRef.id);

      return SmoothResponse.success(data: favorite);
    } catch (e) {
      return SmoothResponse.error(message: 'Error adding favorite: $e');
    }
  }

  /// Supprime un favori par ID.
  Future<SmoothResponse<void>> removeFavorite(String favoriteId) async {
    try {
      await _collection.doc(favoriteId).delete();
      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Error removing favorite: $e');
    }
  }

  /// Supprime un favori par userId et targetId.
  Future<SmoothResponse<void>> removeFavoriteByTarget({
    required String userId,
    required String targetId,
  }) async {
    try {
      final query = await _collection
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      return SmoothResponse.success();
    } catch (e) {
      return SmoothResponse.error(message: 'Error removing favorite: $e');
    }
  }

  /// Toggle favori (ajoute si absent, supprime si présent).
  /// Retourne true si ajouté, false si supprimé.
  Future<SmoothResponse<bool>> toggleFavorite({
    required String userId,
    required String targetId,
    required String type,
    String? targetName,
    String? targetPhotoUrl,
    String? targetSubtitle,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final query = await _collection
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Supprimer
        await query.docs.first.reference.delete();
        return SmoothResponse.success(data: false);
      } else {
        // Ajouter
        await addFavorite(
          userId: userId,
          targetId: targetId,
          type: type,
          targetName: targetName,
          targetPhotoUrl: targetPhotoUrl,
          targetSubtitle: targetSubtitle,
          metadata: metadata,
        );
        return SmoothResponse.success(data: true);
      }
    } catch (e) {
      return SmoothResponse.error(message: 'Error toggling favorite: $e');
    }
  }

  /// Récupère le nombre de favoris d'un utilisateur.
  Future<int> getFavoriteCount(String userId) async {
    final query =
        await _collection.where('userId', isEqualTo: userId).count().get();
    return query.count ?? 0;
  }

  /// Récupère le nombre de favoris par type.
  Future<int> getFavoriteCountByType(String userId, String type) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .count()
        .get();
    return query.count ?? 0;
  }
}
