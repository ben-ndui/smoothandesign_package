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
    return const IAPPurchaseResult._(success: false, error: 'Achat annulé');
  }
}

/// Service de base pour gérer les achats In-App (iOS uniquement)
/// Configurable et réutilisable pour différentes apps
abstract class BaseIAPService {
  final IAPServiceConfig config;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Callback appelé quand un achat est complété
  void Function(IAPPurchaseResult result)? onPurchaseCompleted;

  /// Callback appelé quand un achat échoue
  void Function(String error)? onPurchaseError;

  /// Callback appelé quand des achats sont restaurés
  void Function(List<PurchaseDetails> purchases)? onPurchasesRestored;

  BaseIAPService({required this.config});

  /// Vérifie si IAP est disponible (iOS uniquement)
  bool get isAvailableOnPlatform => Platform.isIOS;

  /// Initialise le service IAP
  Future<void> initialize() async {
    if (!isAvailableOnPlatform) {
      debugPrint('IAP: Non disponible sur cette plateforme (iOS uniquement)');
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('IAP: Store non disponible');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('IAP Stream Error: $error');
        onPurchaseError?.call(error.toString());
      },
    );

    debugPrint('IAP: Service initialisé');
  }

  /// Vérifie si les achats in-app sont disponibles
  Future<bool> isAvailable() async {
    if (!isAvailableOnPlatform) return false;
    return await _iap.isAvailable();
  }

  /// Récupère les produits disponibles
  Future<List<ProductDetails>> getProducts([List<String>? productIds]) async {
    if (!isAvailableOnPlatform) return [];

    final available = await _iap.isAvailable();
    if (!available) return [];

    final ids = productIds ?? config.allProductIds;
    final response = await _iap.queryProductDetails(ids.toSet());

    if (response.error != null) {
      debugPrint('IAP: Erreur query products: ${response.error}');
      return [];
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products non trouvés: ${response.notFoundIDs}');
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
  Future<void> buyProduct(ProductDetails product) async {
    if (!isAvailableOnPlatform) {
      onPurchaseError?.call('IAP disponible uniquement sur iOS');
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      if (isSubscription(product.id)) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('IAP: Erreur achat: $e');
      onPurchaseError?.call(e.toString());
    }
  }

  /// Restaure les achats (abonnements)
  Future<void> restorePurchases() async {
    if (!isAvailableOnPlatform) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP: Erreur restauration: $e');
      onPurchaseError?.call(e.toString());
    }
  }

  /// Gère les mises à jour des achats
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    final restoredPurchases = <PurchaseDetails>[];

    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('IAP: Achat en attente - ${purchase.productID}');
          break;

        case PurchaseStatus.error:
          debugPrint('IAP: Erreur - ${purchase.error?.message}');
          onPurchaseError?.call(purchase.error?.message ?? 'Erreur inconnue');
          _completePurchase(purchase);
          break;

        case PurchaseStatus.purchased:
          debugPrint('IAP: Achat réussi - ${purchase.productID}');
          _verifyAndDeliverProduct(purchase, isRestored: false);
          break;

        case PurchaseStatus.restored:
          debugPrint('IAP: Achat restauré - ${purchase.productID}');
          restoredPurchases.add(purchase);
          _verifyAndDeliverProduct(purchase, isRestored: true);
          break;

        case PurchaseStatus.canceled:
          debugPrint('IAP: Achat annulé - ${purchase.productID}');
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
    // Appeler la méthode de vérification personnalisée (à implémenter)
    final verified = await verifyPurchase(purchase);

    if (verified) {
      // Livrer le produit
      await deliverProduct(purchase);

      onPurchaseCompleted?.call(IAPPurchaseResult.success(
        productId: purchase.productID,
        transactionId: purchase.purchaseID,
        isRestored: isRestored,
      ));
    } else {
      onPurchaseError?.call('Vérification de l\'achat échouée');
    }

    await _completePurchase(purchase);
  }

  /// Marque un achat comme complété
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
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
  /// Par défaut, retourne true (fait confiance au système)
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implémenter la vérification du reçu côté serveur
    return true;
  }

  /// Livre le produit à l'utilisateur (à implémenter par les sous-classes)
  Future<void> deliverProduct(PurchaseDetails purchase);

  /// Dispose le service
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
