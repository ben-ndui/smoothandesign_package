import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Configuration et initialisation Firebase multi-projets.
///
/// Permet d'initialiser Firebase avec différentes configurations
/// et d'accéder aux instances depuis n'importe où dans l'app.
class SmoothFirebase {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;

  /// Initialise Firebase avec les options fournies.
  ///
  /// [options] - Options Firebase (générées par flutterfire configure)
  /// [name] - Nom optionnel pour l'app Firebase (utile pour multi-projets)
  /// [enablePersistence] - Active la persistence Firestore (défaut: true)
  static Future<void> initialize({
    required FirebaseOptions options,
    String? name,
    bool enablePersistence = true,
  }) async {
    _app = await Firebase.initializeApp(
      options: options,
      name: name,
    );

    _auth = FirebaseAuth.instanceFor(app: _app!);
    _firestore = FirebaseFirestore.instanceFor(app: _app!);
    _storage = FirebaseStorage.instanceFor(app: _app!);
    _messaging = FirebaseMessaging.instance;

    if (enablePersistence) {
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  }

  /// Initialise Firebase avec l'app par défaut (déjà initialisée).
  ///
  /// Utile quand Firebase.initializeApp() est appelé ailleurs.
  static void initializeWithDefault() {
    _app = Firebase.app();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _messaging = FirebaseMessaging.instance;
  }

  /// Vérifie si Firebase est initialisé.
  static bool get isInitialized => _app != null;

  /// Instance FirebaseApp.
  static FirebaseApp get app {
    _assertInitialized();
    return _app!;
  }

  /// Instance FirebaseAuth.
  static FirebaseAuth get auth {
    _assertInitialized();
    return _auth!;
  }

  /// Instance FirebaseFirestore.
  static FirebaseFirestore get firestore {
    _assertInitialized();
    return _firestore!;
  }

  /// Instance FirebaseStorage.
  static FirebaseStorage get storage {
    _assertInitialized();
    return _storage!;
  }

  /// Instance FirebaseMessaging.
  static FirebaseMessaging get messaging {
    _assertInitialized();
    return _messaging!;
  }

  /// Utilisateur actuellement connecté (ou null).
  static User? get currentUser => _auth?.currentUser;

  /// UID de l'utilisateur connecté (ou null).
  static String? get currentUserId => _auth?.currentUser?.uid;

  /// Stream des changements d'état d'authentification.
  static Stream<User?> get authStateChanges {
    _assertInitialized();
    return _auth!.authStateChanges();
  }

  /// Référence à une collection Firestore.
  static CollectionReference<Map<String, dynamic>> collection(String path) {
    _assertInitialized();
    return _firestore!.collection(path);
  }

  /// Référence à un document Firestore.
  static DocumentReference<Map<String, dynamic>> doc(String path) {
    _assertInitialized();
    return _firestore!.doc(path);
  }

  /// Vérifie que Firebase est initialisé.
  static void _assertInitialized() {
    if (_app == null) {
      throw StateError(
        'SmoothFirebase non initialisé. '
        'Appelez SmoothFirebase.initialize() ou initializeWithDefault() d\'abord.',
      );
    }
  }

  /// Réinitialise toutes les instances (utile pour les tests).
  static void reset() {
    _app = null;
    _auth = null;
    _firestore = null;
    _storage = null;
    _messaging = null;
  }
}
