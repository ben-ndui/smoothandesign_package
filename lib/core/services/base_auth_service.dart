import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../firebase/smooth_firebase.dart';
import '../models/smooth_response.dart';
import '../models/base_user.dart';
import '../models/base_user_role.dart';

/// Service d'authentification de base avec Email, Google et Apple.
///
/// Étendre cette classe pour ajouter une logique métier spécifique:
/// ```dart
/// class AuthService extends BaseAuthService {
///   @override
///   Future<BaseUser?> getUserFromFirestore(String uid) async {
///     // Charger votre modèle User spécifique
///   }
/// }
/// ```
class BaseAuthService {
  /// Secure storage key for the "app locked" flag. When set, the auth bloc
  /// emits AuthLockedState on CheckAuth instead of AuthAuthenticatedState
  /// — the user has to clear it via biometric verification.
  static const _kIsLockedKey = 'auth.isLocked';

  final FlutterSecureStorage _lockStorage = const FlutterSecureStorage();

  String? _authToken;
  BaseUser? _currentUser;

  /// Apple authorization code en attente de persistence.
  /// Mis à jour par [signInWithApple] quand le user n'a pas encore de doc
  /// Firestore (nouvel utilisateur). Sera flushé dans Firestore par
  /// [completeSocialSignUp] une fois le doc créé.
  String? _pendingAppleAuthCode;

  /// Utilisateur actuellement connecté.
  BaseUser? get currentUser => _currentUser;

  /// Token d'authentification actuel.
  String? get authToken => _authToken;

  /// Vérifie si un utilisateur est connecté.
  bool get isSignedIn => SmoothFirebase.currentUser != null;

  /// Utilisateur Firebase actuel.
  User? get firebaseUser => SmoothFirebase.currentUser;

  /// Stream des changements d'état d'authentification.
  Stream<User?> authStateChanges() => SmoothFirebase.authStateChanges;

  // ===== Méthodes à surcharger =====

  /// Récupère l'utilisateur depuis Firestore.
  /// À surcharger pour charger votre modèle User spécifique.
  Future<BaseUser?> getUserFromFirestore(String uid) async {
    final doc = await SmoothFirebase.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return BaseUser.fromMap(doc.data()!, doc.id);
  }

  /// Sauvegarde un nouvel utilisateur dans Firestore.
  /// À surcharger pour personnaliser la création.
  Future<void> saveUserToFirestore(User firebaseUser, {
    String? name,
    BaseUserRole role = BaseUserRole.user,
    Map<String, dynamic>? extraData,
  }) async {
    final data = {
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'name': name ?? firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? '',
      'displayName': firebaseUser.displayName ?? name ?? '',
      'photoURL': firebaseUser.photoURL ?? '',
      'role': role.name,
      'createdAt': DateTime.now().toIso8601String(),
      ...?extraData,
    };

    // Borné : ce set() est sur le chemin bloquant de l'inscription
    // (AuthLoadingState affiché) — sans timeout, un write jamais ack'é
    // gèle le signup en spinner infini (classe de bug App Review 2.1(a)).
    // Le TimeoutException remonte aux try/catch des flows appelants.
    await SmoothFirebase.collection('users')
        .doc(firebaseUser.uid)
        .set(data)
        .timeout(const Duration(seconds: 10));
  }

  // ===== Inscription =====

  /// Inscription avec email et mot de passe.
  Future<SmoothResponse<BaseUser>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    BaseUserRole role = BaseUserRole.user,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final credential = await SmoothFirebase.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return SmoothResponse(message: "Échec de la création du compte", code: 500);
      }

      await saveUserToFirestore(
        credential.user!,
        name: name,
        role: role,
        extraData: extraData,
      );

      _currentUser = await getUserFromFirestore(credential.user!.uid);
      await _updateFcmToken();

      return SmoothResponse(
        data: _currentUser!,
        message: "Inscription réussie",
        code: 200,
      );
    } on FirebaseAuthException catch (e) {
      return SmoothResponse(message: authErrorMessageFor(e), code: 500);
    } catch (e) {
      return SmoothResponse(message: "Erreur: $e", code: 500);
    }
  }

  // ===== Connexion =====

  /// Connexion avec email et mot de passe.
  Future<SmoothResponse<bool>> signInWithEmail(String email, String password) async {
    try {
      final credential = await SmoothFirebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return SmoothResponse(data: false, message: "Échec de connexion", code: 500);
      }

      _currentUser = await getUserFromFirestore(credential.user!.uid);

      if (_currentUser == null) {
        // Créer un doc minimal si l'utilisateur n'existe pas dans Firestore
        await saveUserToFirestore(credential.user!);
        _currentUser = await getUserFromFirestore(credential.user!.uid);
      }

      await _saveToken(credential.user!.refreshToken);
      await _updateFcmToken();

      return SmoothResponse(data: true, message: "Connexion réussie", code: 200);
    } on FirebaseAuthException catch (e) {
      return SmoothResponse(data: false, message: authErrorMessageFor(e), code: 500);
    } catch (e) {
      return SmoothResponse(data: false, message: "Erreur: $e", code: 500);
    }
  }

  /// Connexion avec Google.
  /// Retourne code 201 si nouvel utilisateur (nécessite sélection de rôle).
  Future<SmoothResponse<bool>> signInWithGoogle() async {
    try {
      debugPrint('🔵 [GoogleSignIn] signInWithGoogle() called');
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      debugPrint('🔵 [GoogleSignIn] googleUser: $googleUser');

      if (googleUser == null) {
        debugPrint('🔵 [GoogleSignIn] cancelled or null');
        return SmoothResponse(data: false, message: "Connexion Google annulée", code: 400);
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await SmoothFirebase.auth.signInWithCredential(credential);

      if (SmoothFirebase.currentUser == null) {
        return SmoothResponse(data: false, message: "Échec connexion Google", code: 500);
      }

      await _saveToken(googleAuth.accessToken);
      _currentUser = await getUserFromFirestore(SmoothFirebase.currentUserId!);

      if (_currentUser == null) {
        // Nouvel utilisateur - retourne 201 pour sélection de rôle
        return SmoothResponse(data: true, message: "Nouvel utilisateur", code: 201);
      }

      await _updateFcmToken();
      return SmoothResponse(data: true, message: "Connexion Google réussie", code: 200);
    } catch (e, stack) {
      debugPrint('❌ [GoogleSignIn] Error: $e');
      debugPrint('❌ [GoogleSignIn] Stack: $stack');
      return SmoothResponse(data: false, message: "Erreur Google: $e", code: 500);
    }
  }

  /// Connexion avec Apple.
  /// Retourne code 201 si nouvel utilisateur (nécessite sélection de rôle).
  Future<SmoothResponse<bool>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await SmoothFirebase.auth.signInWithCredential(oauthCredential);

      if (SmoothFirebase.currentUser == null) {
        return SmoothResponse(data: false, message: "Échec connexion Apple", code: 500);
      }

      // Store authorization code for future token revocation (required by Apple)
      await _storeAppleAuthCode(appleCredential.authorizationCode);

      await _saveToken(appleCredential.identityToken);
      _currentUser = await getUserFromFirestore(SmoothFirebase.currentUserId!);

      if (_currentUser == null) {
        return SmoothResponse(data: true, message: "Nouvel utilisateur", code: 201);
      }

      await _updateFcmToken();
      return SmoothResponse(data: true, message: "Connexion Apple réussie", code: 200);
    } catch (e) {
      return SmoothResponse(data: false, message: "Erreur Apple: $e", code: 500);
    }
  }

  /// Store Apple authorization code for token revocation.
  ///
  /// Utilise `update` (et non `set merge:true`) pour ne JAMAIS pré-créer un
  /// doc Firestore : si le doc n'existe pas (nouvel utilisateur), update
  /// échoue, on cache le code dans [_pendingAppleAuthCode] et il sera
  /// persisté plus tard par [completeSocialSignUp]. Sans ça, un doc minimal
  /// (avec uniquement appleAuthCode + appleAuthCodeUpdatedAt) faisait croire
  /// au `getUserFromFirestore` suivant que le user existait déjà → le
  /// RoleSelector n'était jamais affiché et l'utilisateur restait piégé
  /// avec un rôle par défaut.
  Future<void> _storeAppleAuthCode(String? authCode) async {
    if (authCode == null || SmoothFirebase.currentUserId == null) return;

    try {
      await SmoothFirebase.collection('users')
          .doc(SmoothFirebase.currentUserId!)
          .update({
        'appleAuthCode': authCode,
        'appleAuthCodeUpdatedAt': DateTime.now().toIso8601String(),
      });
      _pendingAppleAuthCode = null;
    } catch (_) {
      // Doc inexistant (nouvel utilisateur) — on stocke en mémoire pour
      // que completeSocialSignUp le persiste après création du doc.
      _pendingAppleAuthCode = authCode;
    }
  }

  /// Complète l'inscription après connexion sociale (pour nouveaux utilisateurs).
  Future<SmoothResponse<BaseUser>> completeSocialSignUp({
    String? name,
    BaseUserRole role = BaseUserRole.user,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      if (SmoothFirebase.currentUser == null) {
        return SmoothResponse(message: "Utilisateur non connecté", code: 401);
      }

      await saveUserToFirestore(
        SmoothFirebase.currentUser!,
        name: name,
        role: role,
        extraData: extraData,
      );

      // Flush l'Apple auth code mis en attente par signInWithApple : le doc
      // existe maintenant, l'update va aboutir.
      if (_pendingAppleAuthCode != null) {
        await _storeAppleAuthCode(_pendingAppleAuthCode);
      }

      _currentUser = await getUserFromFirestore(SmoothFirebase.currentUserId!);
      await _updateFcmToken();

      return SmoothResponse(
        data: _currentUser!,
        message: "Inscription réussie",
        code: 200,
      );
    } catch (e) {
      return SmoothResponse(message: "Erreur: $e", code: 500);
    }
  }

  // ===== Déconnexion =====

  /// Déconnecte l'utilisateur.
  Future<void> signOut() async {
    if (_currentUser != null) {
      try {
        await SmoothFirebase.collection('users')
            .doc(_currentUser!.uid)
            .update({'fcmToken': null});
      } catch (_) {}
    }

    await SmoothFirebase.auth.signOut();
    await GoogleSignIn().signOut();

    _currentUser = null;
    _authToken = null;
    await _clearToken();
    await unlockApp();
  }

  // ===== App lock (biometric quick-relogin) =====

  /// Marque l'app comme verrouillée. Ne touche PAS aux tokens Firebase ou
  /// Google — l'utilisateur reste techniquement connecté, c'est juste l'UI
  /// qui doit demander une vérification biométrique avant de remettre
  /// l'utilisateur au dashboard.
  Future<void> lockApp() async {
    await _lockStorage.write(key: _kIsLockedKey, value: 'true');
  }

  /// Lève le verrou. À appeler depuis l'UI uniquement après une vérification
  /// biométrique réussie — l'AuthBloc ne fait pas la vérif lui-même.
  Future<void> unlockApp() async {
    await _lockStorage.delete(key: _kIsLockedKey);
  }

  /// True si le flag de verrouillage est présent. Ne reflète pas une vraie
  /// déconnexion : `currentUser` peut toujours être valide en parallèle.
  Future<bool> get isAppLocked async {
    final value = await _lockStorage.read(key: _kIsLockedKey);
    return value == 'true';
  }

  // ===== Mot de passe =====

  /// Vérifie les méthodes de connexion pour l'utilisateur connecté.
  /// Retourne ['password'], ['google.com'], ['apple.com'], ou combinaisons.
  List<String> getSignInMethods() {
    final user = SmoothFirebase.currentUser;
    if (user == null) return [];
    return user.providerData.map((info) => info.providerId).toList();
  }

  /// Vérifie si l'utilisateur connecté utilise uniquement OAuth (pas de mot de passe).
  bool isCurrentUserOAuthOnly() {
    final methods = getSignInMethods();
    if (methods.isEmpty) return false;
    return !methods.contains('password');
  }

  /// Envoie un email de réinitialisation de mot de passe.
  /// Note: Firebase ne vérifie plus les providers côté client (sécurité).
  /// L'email ne sera pas envoyé si le compte utilise uniquement OAuth.
  Future<SmoothResponse<bool>> resetPassword(String email) async {
    try {
      await SmoothFirebase.auth.sendPasswordResetEmail(email: email);
      return SmoothResponse(
        data: true,
        message: "Email de réinitialisation envoyé",
        code: 200,
      );
    } on FirebaseAuthException catch (e) {
      return SmoothResponse(data: false, message: authErrorMessageFor(e), code: 500);
    }
  }

  // ===== Suppression de compte =====

  /// Supprime le compte utilisateur.
  /// Pour les utilisateurs OAuth (Apple/Google), appelez d'abord reauthenticateWithProvider.
  Future<SmoothResponse<bool>> deleteAccount() async {
    try {
      final user = SmoothFirebase.currentUser;
      if (user == null) {
        return SmoothResponse(data: false, message: "Non connecté", code: 401);
      }

      // Check if user signed in with Apple and revoke token (required by Apple)
      final isAppleUser = user.providerData.any(
        (info) => info.providerId == 'apple.com',
      );

      if (isAppleUser) {
        await _revokeAppleToken(user.uid);
      }

      // Supprimer les données Firestore
      await SmoothFirebase.collection('users').doc(user.uid).delete();

      // Supprimer le compte Firebase Auth
      await user.delete();

      _currentUser = null;
      return SmoothResponse(data: true, message: "Compte supprimé", code: 200);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return SmoothResponse(
          data: false,
          message: "Reconnectez-vous pour supprimer le compte",
          code: 403,
        );
      }
      return SmoothResponse(data: false, message: e.message ?? "Erreur", code: 500);
    }
  }

  /// Revoke Apple Sign In token (required by Apple for account deletion).
  /// Uses the stored authorization code to call Apple's revoke endpoint.
  Future<void> _revokeAppleToken(String userId) async {
    try {
      // Get stored auth code from Firestore
      final userDoc = await SmoothFirebase.collection('users').doc(userId).get();
      final authCode = userDoc.data()?['appleAuthCode'] as String?;

      if (authCode == null) {
        // No auth code stored - skip revocation (user may have signed up before this feature)
        return;
      }

      // Note: Full Apple token revocation requires server-side implementation
      // because it needs the client_secret which should never be in the app.
      // The authCode is stored for backend use.
      // For now, we just clear the stored code.
      //
      // TODO: Implement server-side revocation via Cloud Function:
      // POST https://appleid.apple.com/auth/revoke
      // with client_id, client_secret, token, and token_type_hint

      // Clear the auth code from Firestore
      await SmoothFirebase.collection('users').doc(userId).update({
        'appleAuthCode': FieldValue.delete(),
        'appleAuthCodeUpdatedAt': FieldValue.delete(),
      });
    } catch (e) {
      // Non-blocking - account deletion should still proceed
    }
  }

  /// Reauthenticate user with Apple Sign In (for sensitive operations).
  Future<SmoothResponse<bool>> reauthenticateWithApple() async {
    try {
      final user = SmoothFirebase.currentUser;
      if (user == null) {
        return SmoothResponse(data: false, message: "Non connecté", code: 401);
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await user.reauthenticateWithCredential(oauthCredential);

      // Update auth code for future revocation
      await _storeAppleAuthCode(appleCredential.authorizationCode);

      return SmoothResponse(data: true, message: "Réauthentification réussie", code: 200);
    } catch (e) {
      return SmoothResponse(data: false, message: "Erreur: $e", code: 500);
    }
  }

  /// Reauthenticate user with Google Sign In (for sensitive operations).
  Future<SmoothResponse<bool>> reauthenticateWithGoogle() async {
    try {
      final user = SmoothFirebase.currentUser;
      if (user == null) {
        return SmoothResponse(data: false, message: "Non connecté", code: 401);
      }

      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        return SmoothResponse(data: false, message: "Connexion Google annulée", code: 400);
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);

      return SmoothResponse(data: true, message: "Réauthentification réussie", code: 200);
    } catch (e) {
      return SmoothResponse(data: false, message: "Erreur: $e", code: 500);
    }
  }

  /// Get the authentication provider for the current user.
  /// Returns 'password', 'google.com', 'apple.com', or null.
  String? getAuthProvider() {
    final user = SmoothFirebase.currentUser;
    if (user == null) return null;

    for (final info in user.providerData) {
      if (info.providerId == 'password') return 'password';
      if (info.providerId == 'google.com') return 'google.com';
      if (info.providerId == 'apple.com') return 'apple.com';
    }
    return null;
  }

  // ===== Helpers internes =====

  Future<void> _updateFcmToken() async {
    if (_currentUser == null) return;

    // Awaité en ligne dans TOUS les flows de connexion : sans borne, un
    // getToken() qui pend (APNS lent) ou un update() Firestore non ack'é
    // laisse le bouton de login en spinner infini alors que l'auth a
    // déjà réussi. 8s max, échec silencieux (le token sera re-poussé par
    // le NotificationService au prochain refresh).
    try {
      final token = await SmoothFirebase.messaging
          .getToken()
          .timeout(const Duration(seconds: 8));
      if (token != null) {
        await SmoothFirebase.collection('users')
            .doc(_currentUser!.uid)
            .update({'fcmToken': token})
            .timeout(const Duration(seconds: 8));
      }
    } catch (_) {}
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Maps a [FirebaseAuthException] to a localised user-facing message.
  /// Static so callers (and tests) can use it without an instance, and
  /// so subclasses can override the wrapping logic without re-mapping.
  @visibleForTesting
  static String authErrorMessageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      // Firebase Auth returns this generic code when
      // `emailPrivacyConfig.enableImprovedEmailPrivacy = true` is set on
      // the project — it intentionally hides whether the failure was
      // wrong-password vs user-not-found. Map it to a single
      // user-friendly message so users don't see the raw
      // "INVALID_LOGIN_CREDENTIALS" string.
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Mot de passe trop faible (min 6 caractères)';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives, réessayez plus tard';
      case 'network-request-failed':
        return 'Connexion internet indisponible';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion est désactivée';
      default:
        return e.message ?? 'Une erreur est survenue';
    }
  }

  /// Recharge l'utilisateur depuis Firestore.
  Future<void> reloadUser() async {
    if (SmoothFirebase.currentUserId != null) {
      _currentUser = await getUserFromFirestore(SmoothFirebase.currentUserId!);
    }
  }
}
