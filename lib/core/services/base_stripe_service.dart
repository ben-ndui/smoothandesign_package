import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

/// Configuration pour le service Stripe
class StripeServiceConfig {
  /// URL de base de l'API Cloud Functions
  final String apiBaseUrl;

  /// Nom de l'app (pour les deep links et metadata)
  final String appName;

  /// Chemin du document Firestore contenant la config Stripe
  final String configDocPath;

  /// URLs de redirection après paiement
  final String successUrl;
  final String cancelUrl;

  const StripeServiceConfig({
    required this.apiBaseUrl,
    required this.appName,
    this.configDocPath = 'app_config/stripe',
    String? successUrl,
    String? cancelUrl,
  })  : successUrl = successUrl ?? '$appName://subscription/success',
        cancelUrl = cancelUrl ?? '$appName://subscription/cancel';
}

/// Service de base pour gérer les paiements Stripe
/// Configurable et réutilisable pour différentes apps
class BaseStripeService {
  final StripeServiceConfig config;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  bool _initialized = false;

  BaseStripeService({
    required this.config,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Initialise Stripe avec la clé publique depuis Firestore
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final parts = config.configDocPath.split('/');
      if (parts.length != 2) {
        throw Exception('configDocPath invalide: ${config.configDocPath}');
      }

      final configDoc =
          await _firestore.collection(parts[0]).doc(parts[1]).get();

      if (!configDoc.exists) {
        throw Exception('Configuration Stripe non trouvée');
      }

      final data = configDoc.data()!;
      final publishableKey = data['publishableKey'] as String?;

      if (publishableKey == null || publishableKey.isEmpty) {
        throw Exception('Clé Stripe non configurée');
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();

      _initialized = true;
    } catch (e) {
      throw Exception('Erreur initialisation Stripe: $e');
    }
  }

  /// Crée une session Checkout pour un abonnement
  Future<SubscriptionCheckoutResult> createSubscriptionCheckout({
    required String userId,
    required String tierId,
    required bool isYearly,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      await initialize();

      final callable = _functions.httpsCallableFromUrl(
        '${config.apiBaseUrl}/stripe/${config.appName}/subscription-checkout',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'tierId': tierId,
        'billingPeriod': isYearly ? 'yearly' : 'monthly',
        'successUrl': successUrl ?? config.successUrl,
        'cancelUrl': cancelUrl ?? config.cancelUrl,
      });

      final data = result.data;
      final url = data['url'] as String?;
      final sessionId = data['session_id'] as String?;

      if (url == null) {
        return SubscriptionCheckoutResult.error('URL de paiement manquante');
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return SubscriptionCheckoutResult.success(sessionId: sessionId);
      } else {
        return SubscriptionCheckoutResult.error(
            'Impossible d\'ouvrir le navigateur');
      }
    } on FirebaseFunctionsException catch (e) {
      return SubscriptionCheckoutResult.error(e.message ?? 'Erreur serveur');
    } catch (e) {
      return SubscriptionCheckoutResult.error(e.toString());
    }
  }

  /// Annule l'abonnement (à la fin de la période en cours)
  Future<CancelSubscriptionResult> cancelSubscription({
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallableFromUrl(
        '${config.apiBaseUrl}/stripe/${config.appName}/cancel',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
      });

      final data = result.data;
      final success = data['success'] as bool? ?? false;
      final currentPeriodEnd = data['currentPeriodEnd'] as String?;

      if (success) {
        return CancelSubscriptionResult.success(
          expiresAt: currentPeriodEnd != null
              ? DateTime.parse(currentPeriodEnd)
              : null,
        );
      } else {
        return CancelSubscriptionResult.error('Échec de l\'annulation');
      }
    } on FirebaseFunctionsException catch (e) {
      return CancelSubscriptionResult.error(e.message ?? 'Erreur serveur');
    } catch (e) {
      return CancelSubscriptionResult.error(e.toString());
    }
  }

  /// Ouvre le portail client Stripe pour gérer l'abonnement
  Future<bool> openCustomerPortal({
    required String userId,
    String? returnUrl,
  }) async {
    try {
      final callable = _functions.httpsCallableFromUrl(
        '${config.apiBaseUrl}/stripe/${config.appName}/customer-portal',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'returnUrl': returnUrl,
      });

      final url = result.data['url'] as String?;

      if (url == null) return false;

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crée un PaymentIntent pour un paiement unique
  Future<PaymentIntentResult> createPaymentIntent({
    required String userId,
    required int amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await initialize();

      final callable = _functions.httpsCallableFromUrl(
        '${config.apiBaseUrl}/stripe/payment-intents',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'metadata': metadata,
      });

      final data = result.data;
      return PaymentIntentResult.success(
        clientSecret: data['clientSecret'] as String,
        customerId: data['customer'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      return PaymentIntentResult.error(e.message ?? 'Erreur serveur');
    } catch (e) {
      return PaymentIntentResult.error(e.toString());
    }
  }
}

/// Résultat d'une création de checkout
class SubscriptionCheckoutResult {
  final bool success;
  final String? sessionId;
  final String? error;

  SubscriptionCheckoutResult._({
    required this.success,
    this.sessionId,
    this.error,
  });

  factory SubscriptionCheckoutResult.success({String? sessionId}) {
    return SubscriptionCheckoutResult._(
      success: true,
      sessionId: sessionId,
    );
  }

  factory SubscriptionCheckoutResult.error(String message) {
    return SubscriptionCheckoutResult._(
      success: false,
      error: message,
    );
  }
}

/// Résultat d'une annulation
class CancelSubscriptionResult {
  final bool success;
  final DateTime? expiresAt;
  final String? error;

  CancelSubscriptionResult._({
    required this.success,
    this.expiresAt,
    this.error,
  });

  factory CancelSubscriptionResult.success({DateTime? expiresAt}) {
    return CancelSubscriptionResult._(
      success: true,
      expiresAt: expiresAt,
    );
  }

  factory CancelSubscriptionResult.error(String message) {
    return CancelSubscriptionResult._(
      success: false,
      error: message,
    );
  }
}

/// Résultat d'un PaymentIntent
class PaymentIntentResult {
  final bool success;
  final String? clientSecret;
  final String? customerId;
  final String? error;

  PaymentIntentResult._({
    required this.success,
    this.clientSecret,
    this.customerId,
    this.error,
  });

  factory PaymentIntentResult.success({
    required String clientSecret,
    String? customerId,
  }) {
    return PaymentIntentResult._(
      success: true,
      clientSecret: clientSecret,
      customerId: customerId,
    );
  }

  factory PaymentIntentResult.error(String message) {
    return PaymentIntentResult._(
      success: false,
      error: message,
    );
  }
}
