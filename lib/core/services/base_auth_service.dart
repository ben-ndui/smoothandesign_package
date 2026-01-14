import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _authToken;
  BaseUser? _currentUser;

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

    await SmoothFirebase.collection('users').doc(firebaseUser.uid).set(data);
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
      return SmoothResponse(message: _getErrorMessage(e), code: 500);
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
      return SmoothResponse(data: false, message: _getErrorMessage(e), code: 500);
    } catch (e) {
      return SmoothResponse(data: false, message: "Erreur: $e", code: 500);
    }
  }

  /// Connexion avec Google.
  /// Retourne code 201 si nouvel utilisateur (nécessite sélection de rôle).
  Future<SmoothResponse<bool>> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();

      if (googleUser == null) {
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
    } catch (e) {
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
  }

  // ===== Mot de passe =====

  /// Vérifie les méthodes de connexion pour un email.
  /// Retourne ['password'], ['google.com'], ['apple.com'], ou combinaisons.
  Future<List<String>> getSignInMethodsForEmail(String email) async {
    try {
      return await SmoothFirebase.auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      return [];
    }
  }

  /// Vérifie si un email utilise uniquement OAuth (pas de mot de passe).
  Future<bool> isOAuthOnlyAccount(String email) async {
    final methods = await getSignInMethodsForEmail(email);
    if (methods.isEmpty) return false; // Compte n'existe pas
    return !methods.contains('password');
  }

  /// Envoie un email de réinitialisation de mot de passe.
  /// Retourne code 403 si le compte utilise uniquement Google/Apple.
  Future<SmoothResponse<bool>> resetPassword(String email) async {
    try {
      // Vérifier si le compte utilise OAuth uniquement
      final methods = await getSignInMethodsForEmail(email);

      if (methods.isEmpty) {
        // Compte n'existe pas - on envoie quand même pour éviter l'énumération
        await SmoothFirebase.auth.sendPasswordResetEmail(email: email);
        return SmoothResponse(
          data: true,
          message: "Email de réinitialisation envoyé",
          code: 200,
        );
      }

      if (!methods.contains('password')) {
        // Compte OAuth uniquement (Google ou Apple)
        // Retourne le provider dans message pour localisation côté UI
        final provider = methods.contains('google.com') ? 'Google' : 'Apple';
        return SmoothResponse(
          data: false,
          message: provider, // UI will use this for localization
          code: 403,
        );
      }

      await SmoothFirebase.auth.sendPasswordResetEmail(email: email);
      return SmoothResponse(
        data: true,
        message: "Email de réinitialisation envoyé",
        code: 200,
      );
    } on FirebaseAuthException catch (e) {
      return SmoothResponse(data: false, message: _getErrorMessage(e), code: 500);
    }
  }

  // ===== Suppression de compte =====

  /// Supprime le compte utilisateur.
  Future<SmoothResponse<bool>> deleteAccount() async {
    try {
      final user = SmoothFirebase.currentUser;
      if (user == null) {
        return SmoothResponse(data: false, message: "Non connecté", code: 401);
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

  // ===== Helpers internes =====

  Future<void> _updateFcmToken() async {
    if (_currentUser == null) return;

    try {
      final token = await SmoothFirebase.messaging.getToken();
      if (token != null) {
        await SmoothFirebase.collection('users')
            .doc(_currentUser!.uid)
            .update({'fcmToken': token});
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

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
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
