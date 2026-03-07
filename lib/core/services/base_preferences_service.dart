import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/smooth_firebase.dart';

/// Service de préférences utilisateur avec stockage local et Firestore.
///
/// Les préférences sont stockées localement (SharedPreferences) pour un accès
/// rapide et synchronisées avec Firestore pour la persistance cloud.
class BasePreferencesService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _rememberEmailKey = 'remember_email_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _quickLoginEnabledKey = 'quick_login_enabled';
  static const String _quickLoginDisplayNameKey = 'quick_login_display_name';
  static const String _quickLoginEmailKey = 'quick_login_email';
  static const String _quickLoginPhotoUrlKey = 'quick_login_photo_url';
  static const String _quickLoginRoleKey = 'quick_login_role';
  static const String _quickLoginProviderKey = 'quick_login_provider';

  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'fr';
  bool _notificationsEnabled = true;
  bool _rememberEmailEnabled = true;
  String? _savedEmail;
  bool _quickLoginEnabled = false;
  String? _quickLoginDisplayName;
  String? _quickLoginEmail;
  String? _quickLoginPhotoUrl;
  String? _quickLoginRole;
  String? _quickLoginProvider;
  bool _isLoaded = false;

  /// Mode de thème actuel.
  ThemeMode get themeMode => _themeMode;

  /// Langue actuelle.
  String get language => _language;

  /// Notifications activées.
  bool get notificationsEnabled => _notificationsEnabled;

  /// Mémorisation de l'email activée.
  bool get rememberEmailEnabled => _rememberEmailEnabled;

  /// Email sauvegardé.
  String? get savedEmail => _savedEmail;

  /// Quick login activé.
  bool get quickLoginEnabled => _quickLoginEnabled;

  /// Nom d'affichage pour quick login.
  String? get quickLoginDisplayName => _quickLoginDisplayName;

  /// Email pour quick login.
  String? get quickLoginEmail => _quickLoginEmail;

  /// Photo URL pour quick login.
  String? get quickLoginPhotoUrl => _quickLoginPhotoUrl;

  /// Rôle pour quick login.
  String? get quickLoginRole => _quickLoginRole;

  /// Provider pour quick login (email, google, apple).
  String? get quickLoginProvider => _quickLoginProvider;

  /// Indique si les préférences sont chargées.
  bool get isLoaded => _isLoaded;

  /// Charge les préférences depuis le stockage local.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(_themeKey);
    _themeMode = _themeModeFromString(themeName);

    _language = prefs.getString(_languageKey) ?? 'fr';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _rememberEmailEnabled = prefs.getBool(_rememberEmailKey) ?? true;
    _savedEmail = prefs.getString(_savedEmailKey);
    _quickLoginEnabled = prefs.getBool(_quickLoginEnabledKey) ?? false;
    _quickLoginDisplayName = prefs.getString(_quickLoginDisplayNameKey);
    _quickLoginEmail = prefs.getString(_quickLoginEmailKey);
    _quickLoginPhotoUrl = prefs.getString(_quickLoginPhotoUrlKey);
    _quickLoginRole = prefs.getString(_quickLoginRoleKey);
    _quickLoginProvider = prefs.getString(_quickLoginProviderKey);

    _isLoaded = true;
    notifyListeners();
  }

  /// Charge les préférences depuis Firestore pour un utilisateur.
  Future<void> loadFromFirestore(String userId) async {
    try {
      final doc = await SmoothFirebase.collection('user_preferences')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data['themeMode'] != null) {
          _themeMode = _themeModeFromString(data['themeMode']);
        }
        if (data['language'] != null) {
          _language = data['language'];
        }
        if (data['notificationsEnabled'] != null) {
          _notificationsEnabled = data['notificationsEnabled'];
        }

        // Synchroniser avec le stockage local
        await _saveToLocal();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      // Utiliser les valeurs locales en cas d'erreur
    }
  }

  /// Définit le mode de thème.
  Future<void> setThemeMode(ThemeMode mode, {String? userId}) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);

    if (userId != null) {
      await _saveToFirestore(userId);
    }
  }

  /// Définit la langue.
  Future<void> setLanguage(String language, {String? userId}) async {
    _language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);

    if (userId != null) {
      await _saveToFirestore(userId);
    }
  }

  /// Active/désactive les notifications.
  Future<void> setNotificationsEnabled(bool enabled, {String? userId}) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);

    if (userId != null) {
      await _saveToFirestore(userId);
    }
  }

  /// Active/désactive la mémorisation de l'email.
  Future<void> setRememberEmailEnabled(bool enabled) async {
    _rememberEmailEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEmailKey, enabled);

    // Si désactivé, supprimer l'email sauvegardé
    if (!enabled) {
      _savedEmail = null;
      await prefs.remove(_savedEmailKey);
    }
  }

  /// Sauvegarde l'email de connexion.
  Future<void> setSavedEmail(String? email) async {
    if (!_rememberEmailEnabled) return;

    _savedEmail = email;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  /// Sauvegarde les données de connexion rapide.
  Future<void> setQuickLoginData({
    required String displayName,
    required String email,
    required String role,
    required String provider,
    String? photoUrl,
  }) async {
    _quickLoginEnabled = true;
    _quickLoginDisplayName = displayName;
    _quickLoginEmail = email;
    _quickLoginRole = role;
    _quickLoginProvider = provider;
    _quickLoginPhotoUrl = photoUrl;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickLoginEnabledKey, true);
    await prefs.setString(_quickLoginDisplayNameKey, displayName);
    await prefs.setString(_quickLoginEmailKey, email);
    await prefs.setString(_quickLoginRoleKey, role);
    await prefs.setString(_quickLoginProviderKey, provider);
    if (photoUrl != null) {
      await prefs.setString(_quickLoginPhotoUrlKey, photoUrl);
    } else {
      await prefs.remove(_quickLoginPhotoUrlKey);
    }
  }

  /// Efface les données de connexion rapide.
  Future<void> clearQuickLoginData() async {
    _quickLoginEnabled = false;
    _quickLoginDisplayName = null;
    _quickLoginEmail = null;
    _quickLoginPhotoUrl = null;
    _quickLoginRole = null;
    _quickLoginProvider = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickLoginEnabledKey);
    await prefs.remove(_quickLoginDisplayNameKey);
    await prefs.remove(_quickLoginEmailKey);
    await prefs.remove(_quickLoginPhotoUrlKey);
    await prefs.remove(_quickLoginRoleKey);
    await prefs.remove(_quickLoginProviderKey);
  }

  /// Réinitialise les préférences aux valeurs par défaut.
  Future<void> resetToDefaults({String? userId}) async {
    _themeMode = ThemeMode.system;
    _language = 'fr';
    _notificationsEnabled = true;
    notifyListeners();

    await _saveToLocal();

    if (userId != null) {
      await _saveToFirestore(userId);
    }
  }

  /// Stream des préférences depuis Firestore.
  Stream<Map<String, dynamic>?> streamPreferences(String userId) {
    return SmoothFirebase.collection('user_preferences')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.name);
    await prefs.setString(_languageKey, _language);
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
  }

  Future<void> _saveToFirestore(String userId) async {
    try {
      await SmoothFirebase.collection('user_preferences').doc(userId).set({
        'themeMode': _themeMode.name,
        'language': _language,
        'notificationsEnabled': _notificationsEnabled,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail - local preferences are still saved
    }
  }

  ThemeMode _themeModeFromString(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
