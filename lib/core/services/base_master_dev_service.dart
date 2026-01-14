import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/base_user.dart';

/// Service abstrait pour les fonctionnalités de développeur maître.
///
/// Étendre cette classe dans votre app pour configurer l'email et les collections:
/// ```dart
/// class MasterDevService extends BaseMasterDevService {
///   @override
///   String get masterDevEmail => 'your.email@example.com';
///
///   @override
///   List<String> get mainCollections => ['users', 'products', ...];
/// }
/// ```
abstract class BaseMasterDevService {
  final FirebaseFirestore _firestore;

  /// Email du développeur maître - à override dans l'app.
  String get masterDevEmail;

  /// Collections à explorer dans le Database Explorer - à override dans l'app.
  List<String> get mainCollections;

  BaseMasterDevService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== MASTER DEV CHECK ====================

  /// Vérifie si l'utilisateur est le développeur maître.
  bool isMasterDev(BaseUser? user) {
    if (user == null) return false;
    return user.email.toLowerCase() == masterDevEmail.toLowerCase();
  }

  // ==================== FEATURE FLAGS ====================

  /// Récupère tous les feature flags globaux.
  Future<Map<String, bool>> getFeatureFlags() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('feature_flags')
          .get();
      if (!doc.exists || doc.data() == null) return {};
      return doc.data()!.map((key, value) => MapEntry(key, value == true));
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.getFeatureFlags error: $e');
      return {};
    }
  }

  /// Stream des feature flags pour les mises à jour en temps réel.
  Stream<Map<String, bool>> streamFeatureFlags() {
    return _firestore
        .collection('app_config')
        .doc('feature_flags')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return <String, bool>{};
      return doc.data()!.map((key, value) => MapEntry(key, value == true));
    });
  }

  /// Active/désactive un feature flag.
  Future<bool> setFeatureFlag(String key, bool value) async {
    try {
      await _firestore.collection('app_config').doc('feature_flags').set(
        {key: value},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.setFeatureFlag error: $e');
      return false;
    }
  }

  /// Supprime un feature flag.
  Future<bool> deleteFeatureFlag(String key) async {
    try {
      await _firestore.collection('app_config').doc('feature_flags').update({
        key: FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.deleteFeatureFlag error: $e');
      return false;
    }
  }

  /// Vérifie si le mode maintenance est activé.
  Future<bool> isMaintenanceMode() async {
    final flags = await getFeatureFlags();
    return flags['maintenanceMode'] == true;
  }

  // ==================== DATABASE EXPLORER ====================

  /// Récupère les documents d'une collection (limité).
  Future<List<Map<String, dynamic>>> getCollectionDocuments(
    String collection, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.getCollectionDocuments error: $e');
      return [];
    }
  }

  /// Récupère un document spécifique par ID.
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['_documentId'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.getDocument error: $e');
      return null;
    }
  }

  /// Met à jour un champ spécifique d'un document.
  Future<bool> updateDocumentField(
    String collection,
    String docId,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        field: value,
      });
      return true;
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.updateDocumentField error: $e');
      return false;
    }
  }

  // ==================== USER MANAGEMENT (IMPERSONATION) ====================

  /// Récupère tous les utilisateurs pour l'impersonation.
  /// À override si vous utilisez un modèle User personnalisé.
  Future<List<BaseUser>> getAllUsers({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isDeleted', isNotEqualTo: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => BaseUser.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.getAllUsers error: $e');
      return [];
    }
  }

  /// Recherche des utilisateurs par email ou nom.
  Future<List<BaseUser>> searchUsers(String query) async {
    if (query.isEmpty) return getAllUsers();
    try {
      final queryLower = query.toLowerCase();

      // Search by email
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(20)
          .get();

      // Search by name
      final nameSnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      // Combine and deduplicate
      final users = <String, BaseUser>{};
      for (final doc in [...emailSnapshot.docs, ...nameSnapshot.docs]) {
        users[doc.id] = BaseUser.fromMap(doc.data(), doc.id);
      }

      return users.values.toList();
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.searchUsers error: $e');
      return [];
    }
  }

  /// Récupère un utilisateur par ID pour l'impersonation.
  Future<BaseUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return BaseUser.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ BaseMasterDevService.getUserById error: $e');
      return null;
    }
  }
}
