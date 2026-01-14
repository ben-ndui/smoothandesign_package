import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_tier.dart';

/// Service générique pour la gestion des tiers d'abonnement.
///
/// Usage:
/// ```dart
/// final subscriptionService = BaseSubscriptionService(
///   collectionName: 'myapp_subscription_tiers',
///   defaultTiers: [myFreeTier, myProTier],
/// );
///
/// // Stream des tiers
/// subscriptionService.streamTiers().listen((tiers) {
///   print('Available tiers: ${tiers.map((t) => t.name)}');
/// });
///
/// // Vérifier une limite
/// final canAdd = await subscriptionService.checkLimit(
///   tierId: 'pro',
///   limitKey: 'maxUsers',
///   currentCount: 5,
/// );
/// ```
class BaseSubscriptionService {
  final FirebaseFirestore _firestore;
  final String collectionName;
  final List<SubscriptionTier> defaultTiers;

  // Cache local
  List<SubscriptionTier>? _cachedTiers;
  DateTime? _lastFetch;
  final Duration cacheDuration;

  BaseSubscriptionService({
    FirebaseFirestore? firestore,
    this.collectionName = 'subscription_tiers',
    this.defaultTiers = const [],
    this.cacheDuration = const Duration(minutes: 5),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Stream de tous les tiers triés par ordre.
  Stream<List<SubscriptionTier>> streamTiers() {
    return _collection.orderBy('sortOrder').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => SubscriptionTier.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  /// Récupère tous les tiers (avec cache).
  Future<List<SubscriptionTier>> getTiers({bool forceRefresh = false}) async {
    // Vérifier le cache
    if (!forceRefresh && _cachedTiers != null && _lastFetch != null) {
      final elapsed = DateTime.now().difference(_lastFetch!);
      if (elapsed < cacheDuration) {
        return _cachedTiers!;
      }
    }

    try {
      final snapshot = await _collection.orderBy('sortOrder').get();

      if (snapshot.docs.isEmpty && defaultTiers.isNotEmpty) {
        await _initializeDefaultTiers();
        return defaultTiers;
      }

      _cachedTiers = snapshot.docs
          .map((doc) => SubscriptionTier.fromMap(doc.data(), id: doc.id))
          .toList();
      _lastFetch = DateTime.now();

      return _cachedTiers!;
    } catch (e) {
      debugPrint('Error fetching tiers: $e');
      return _cachedTiers ?? defaultTiers;
    }
  }

  /// Récupère un tier spécifique.
  Future<SubscriptionTier?> getTier(String tierId) async {
    // Chercher dans le cache d'abord
    if (_cachedTiers != null) {
      final cached = _cachedTiers!.where((t) => t.id == tierId).firstOrNull;
      if (cached != null) return cached;
    }

    try {
      final doc = await _collection.doc(tierId).get();
      if (!doc.exists) return null;

      return SubscriptionTier.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Error fetching tier $tierId: $e');
      return defaultTiers.where((t) => t.id == tierId).firstOrNull;
    }
  }

  /// Met à jour un tier.
  Future<void> updateTier(SubscriptionTier tier) async {
    try {
      await _collection.doc(tier.id).set(tier.toMap(), SetOptions(merge: true));
      invalidateCache();
    } catch (e) {
      debugPrint('Error updating tier ${tier.id}: $e');
      rethrow;
    }
  }

  /// Crée un nouveau tier.
  Future<void> createTier(SubscriptionTier tier) async {
    try {
      await _collection.doc(tier.id).set(tier.toMap());
      invalidateCache();
    } catch (e) {
      debugPrint('Error creating tier ${tier.id}: $e');
      rethrow;
    }
  }

  /// Supprime un tier.
  Future<void> deleteTier(String tierId, {String? protectedTierId}) async {
    if (protectedTierId != null && tierId == protectedTierId) {
      throw Exception('This tier cannot be deleted');
    }

    try {
      await _collection.doc(tierId).delete();
      invalidateCache();
    } catch (e) {
      debugPrint('Error deleting tier $tierId: $e');
      rethrow;
    }
  }

  /// Vérifie une limite pour un tier.
  Future<bool> checkLimit({
    required String tierId,
    required String limitKey,
    required int currentCount,
  }) async {
    final tier = await getTier(tierId);
    if (tier == null) return false;
    return tier.checkLimit(limitKey, currentCount: currentCount);
  }

  /// Vérifie si un tier a une feature.
  Future<bool> hasFeature({
    required String tierId,
    required String featureKey,
  }) async {
    final tier = await getTier(tierId);
    if (tier == null) return false;
    return tier.hasFeature(featureKey);
  }

  /// Initialise les tiers par défaut.
  Future<void> _initializeDefaultTiers() async {
    if (defaultTiers.isEmpty) return;

    final batch = _firestore.batch();

    for (final tier in defaultTiers) {
      batch.set(_collection.doc(tier.id), tier.toMap());
    }

    await batch.commit();
    debugPrint('Default tiers initialized');
  }

  /// Invalide le cache manuellement.
  void invalidateCache() {
    _cachedTiers = null;
    _lastFetch = null;
  }
}
