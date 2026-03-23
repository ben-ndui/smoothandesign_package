import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Re-export les types de in_app_purchase pour les apps qui utilisent le package
export 'package:in_app_purchase/in_app_purchase.dart'
    show ProductDetails, PurchaseDetails, PurchaseStatus;

/// Configuration pour le service IAP
class IAPServiceConfig {
  /// Identifiant du bundle/package de l'app
  final String appBundleId;

  /// Product IDs pour les abonnements (non-consumable)
  final List<String> subscriptionProductIds;

  /// Product IDs pour les achats uniques (consumable)
  final List<String> consumableProductIds;

  const IAPServiceConfig({
    required this.appBundleId,
    this.subscriptionProductIds = const [],
    this.consumableProductIds = const [],
  });

  /// Tous les product IDs
  List<String> get allProductIds => [
        ...subscriptionProductIds,
        ...consumableProductIds,
      ];
}

/// Résultat d'un achat
class IAPPurchaseResult {
  final bool success;
  final String? productId;
  final String? transactionId;
  final String? error;
  final bool isRestored;

  const IAPPurchaseResult._({
    required this.success,
    this.productId,
    this.transactionId,
    this.error,
    this.isRestored = false,
  });

  factory IAPPurchaseResult.success({
    required String productId,
    String? transactionId,
    bool isRestored = false,
  }) {
    return IAPPurchaseResult._(
      success: true,
      productId: productId,
      transactionId: transactionId,
      isRestored: isRestored,
    );
  }

  factory IAPPurchaseResult.error(String message) {
    return IAPPurchaseResult._(success: false, error: message);
  }

  factory IAPPurchaseResult.cancelled() {
    return const IAPPurchaseResult._(
      success: false,
      error: 'Achat annulé',
    );
  }
}

/// Service de base pour gérer les achats In-App (iOS uniquement)
/// Configurable et réutilisable pour différentes apps
abstract class BaseIAPService {
  final IAPServiceConfig config;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;

  /// Callback appelé quand un achat est complété
  void Function(IAPPurchaseResult result)? onPurchaseCompleted;

  /// Callback appelé quand un achat échoue
  void Function(String error)? onPurchaseError;

  /// Callback appelé quand des achats sont restaurés
  void Function(List<PurchaseDetails> purchases)? onPurchasesRestored;

  BaseIAPService({required this.config});

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Vérifie si IAP est disponible (iOS uniquement)
  bool get isAvailableOnPlatform => Platform.isIOS;

  /// Indique si le service a été initialisé
  bool get isInitialized => _initialized;

  /// Initialise le service IAP
  Future<void> initialize() async {
    if (!isAvailableOnPlatform) {
      _log('IAP: Non disponible sur cette plateforme');
      return;
    }

    // Guard against double-initialization
    if (_initialized && _subscription != null) {
      _log('IAP: Déjà initialisé, skip');
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _log('IAP: Store non disponible');
      return;
    }

    // Cancel any previous subscription before creating a new one
    await _subscription?.cancel();

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () {
        _log('IAP: purchaseStream done');
        _subscription?.cancel();
      },
      onError: (error) {
        _log('IAP: purchaseStream error: $error');
        onPurchaseError?.call(error.toString());
      },
    );

    _initialized = true;
    _log('IAP: Service initialisé');
  }

  /// Vérifie si les achats in-app sont disponibles
  Future<bool> isAvailable() async {
    if (!isAvailableOnPlatform) return false;
    return await _iap.isAvailable();
  }

  /// Récupère les produits disponibles
  Future<List<ProductDetails>> getProducts([
    List<String>? productIds,
  ]) async {
    if (!isAvailableOnPlatform) return [];

    final available = await _iap.isAvailable();
    if (!available) return [];

    final ids = productIds ?? config.allProductIds;
    final response = await _iap.queryProductDetails(ids.toSet());

    if (response.error != null) {
      _log('IAP: Erreur query products: ${response.error}');
      return [];
    }

    if (response.notFoundIDs.isNotEmpty) {
      _log('IAP: Products non trouvés: ${response.notFoundIDs}');
    }

    return response.productDetails;
  }

  /// Récupère uniquement les abonnements
  Future<List<ProductDetails>> getSubscriptions() async {
    return await getProducts(config.subscriptionProductIds);
  }

  /// Récupère uniquement les achats consommables
  Future<List<ProductDetails>> getConsumables() async {
    return await getProducts(config.consumableProductIds);
  }

  /// Lance un achat
  Future<bool> buyProduct(ProductDetails product) async {
    if (!isAvailableOnPlatform) {
      onPurchaseError?.call('IAP disponible uniquement sur iOS');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      bool started;
      if (isSubscription(product.id)) {
        started = await _iap.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        started = await _iap.buyConsumable(
          purchaseParam: purchaseParam,
        );
      }
      _log('IAP: buyProduct started=$started for ${product.id}');
      if (!started) {
        onPurchaseError?.call('Impossible de lancer l\'achat');
      }
      return started;
    } catch (e) {
      _log('IAP: Erreur achat: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  /// Restaure les achats (abonnements)
  Future<void> restorePurchases() async {
    if (!isAvailableOnPlatform) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _log('IAP: Erreur restauration: $e');
      onPurchaseError?.call(e.toString());
    }
  }

  /// Gère les mises à jour des achats
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    _log('IAP: purchaseStream event — '
        '${purchaseDetailsList.length} purchase(s)');

    final restoredPurchases = <PurchaseDetails>[];

    for (final purchase in purchaseDetailsList) {
      _log('IAP: ${purchase.productID} → ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _log('IAP: Achat en attente - ${purchase.productID}');
          break;

        case PurchaseStatus.error:
          _log('IAP: Erreur - ${purchase.error?.message}');
          onPurchaseError?.call(
            purchase.error?.message ?? 'Erreur inconnue',
          );
          _completePurchase(purchase);
          break;

        case PurchaseStatus.purchased:
          _log('IAP: Achat réussi - ${purchase.productID}');
          _verifyAndDeliverProduct(purchase, isRestored: false);
          break;

        case PurchaseStatus.restored:
          _log('IAP: Achat restauré - ${purchase.productID}');
          restoredPurchases.add(purchase);
          _verifyAndDeliverProduct(purchase, isRestored: true);
          break;

        case PurchaseStatus.canceled:
          _log('IAP: Achat annulé - ${purchase.productID}');
          onPurchaseCompleted?.call(IAPPurchaseResult.cancelled());
          _completePurchase(purchase);
          break;
      }
    }

    if (restoredPurchases.isNotEmpty) {
      onPurchasesRestored?.call(restoredPurchases);
    }
  }

  /// Vérifie et livre le produit acheté
  Future<void> _verifyAndDeliverProduct(
    PurchaseDetails purchase, {
    required bool isRestored,
  }) async {
    try {
      final verified = await verifyPurchase(purchase);

      if (verified) {
        await deliverProduct(purchase);

        onPurchaseCompleted?.call(IAPPurchaseResult.success(
          productId: purchase.productID,
          transactionId: purchase.purchaseID,
          isRestored: isRestored,
        ));
      } else {
        _log('IAP: Vérification échouée pour ${purchase.productID}');
        onPurchaseError?.call('Vérification de l\'achat échouée');
      }
    } catch (e) {
      _log('IAP: Erreur verify/deliver: $e');
      onPurchaseError?.call(e.toString());
    }

    // Always complete the purchase to unblock the queue
    await _completePurchase(purchase);
  }

  /// Marque un achat comme complété
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      _log('IAP: completing purchase ${purchase.productID}');
      await _iap.completePurchase(purchase);
    }
  }

  /// Vérifie si un product ID est un abonnement
  bool isSubscription(String productId) {
    return config.subscriptionProductIds.contains(productId);
  }

  /// Vérifie si un product ID est un consommable
  bool isConsumable(String productId) {
    return config.consumableProductIds.contains(productId);
  }

  /// Vérifie l'achat côté serveur (à implémenter par les sous-classes)
  /// Par défaut, retourne true (fait confiance au système StoreKit)
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    return true;
  }

  /// Livre le produit à l'utilisateur (à implémenter par les sous-classes)
  Future<void> deliverProduct(PurchaseDetails purchase);

  /// Dispose le service
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
