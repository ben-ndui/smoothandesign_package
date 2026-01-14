import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de chiffrement AES-256 pour les données sensibles.
///
/// Utilise une clé dérivée du serveur ou générée localement en fallback.
/// Les clés sont stockées de manière sécurisée via flutter_secure_storage.
///
/// Usage:
/// ```dart
/// final encryption = EncryptionService();
///
/// // Initialiser pour un utilisateur
/// await encryption.initialize(userId);
///
/// // Chiffrer/déchiffrer des chaînes
/// final encrypted = encryption.encryptString('sensitive data');
/// final decrypted = encryption.decryptString(encrypted);
///
/// // Chiffrer des maps
/// final encryptedData = encryption.encryptFields(data, ['password', 'token']);
/// ```
class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';

  final FlutterSecureStorage _secureStorage;
  final FirebaseFunctions _functions;

  /// Nom de la Cloud Function pour récupérer la clé (peut être personnalisé).
  final String keyFunctionName;

  /// Salt utilisé pour la génération de clé locale.
  final String localSalt;

  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;

  EncryptionService({
    FlutterSecureStorage? secureStorage,
    FirebaseFunctions? functions,
    this.keyFunctionName = 'getEncryptionKey',
    this.localSalt = 'smooth_local_salt_2024',
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _functions = functions ?? FirebaseFunctions.instance;

  /// Initialise le service avec la clé de chiffrement pour l'utilisateur.
  Future<void> initialize(String userId) async {
    // Vérifier si on a déjà une clé stockée
    final storedKey = await _secureStorage.read(key: '$_keyStorageKey:$userId');
    final storedIv = await _secureStorage.read(key: '$_ivStorageKey:$userId');

    if (storedKey != null && storedIv != null) {
      _encryptionKey = encrypt.Key.fromBase64(storedKey);
      _iv = encrypt.IV.fromBase64(storedIv);
      return;
    }

    // Sinon, demander une nouvelle clé au serveur
    await _fetchAndStoreKey(userId);
  }

  /// Récupère la clé de chiffrement depuis le serveur.
  Future<void> _fetchAndStoreKey(String userId) async {
    try {
      final callable = _functions.httpsCallable(keyFunctionName);
      final result = await callable.call<Map<String, dynamic>>({'userId': userId});

      final keyData = result.data;
      final keyString = keyData['key'] as String;
      final ivString = keyData['iv'] as String;

      // Dériver la clé AES-256 à partir de la clé serveur
      final derivedKey = _deriveKey(keyString, userId);

      _encryptionKey = encrypt.Key(Uint8List.fromList(derivedKey));
      _iv = encrypt.IV.fromBase64(ivString);

      // Stocker de manière sécurisée
      await _secureStorage.write(
        key: '$_keyStorageKey:$userId',
        value: _encryptionKey!.base64,
      );
      await _secureStorage.write(
        key: '$_ivStorageKey:$userId',
        value: _iv!.base64,
      );
    } catch (e) {
      debugPrint('Erreur récupération clé: $e');
      // Fallback: générer une clé locale (moins sécurisé mais fonctionnel)
      _generateLocalKey(userId);
    }
  }

  /// Génère une clé locale en fallback.
  void _generateLocalKey(String userId) {
    final derivedKey = _deriveKey(userId, localSalt);
    _encryptionKey = encrypt.Key(Uint8List.fromList(derivedKey));
    _iv = encrypt.IV.fromSecureRandom(16);
  }

  /// Dérive une clé AES-256 (32 bytes) à partir d'une chaîne.
  List<int> _deriveKey(String secret, String salt) {
    final key = utf8.encode('$secret:$salt');
    final hash = sha256.convert(key);
    return hash.bytes; // SHA-256 = 32 bytes = AES-256
  }

  /// Chiffre une chaîne de caractères.
  ///
  /// Retourne la chaîne originale si le service n'est pas initialisé.
  String? encryptString(String? plainText) {
    if (plainText == null || plainText.isEmpty) return plainText;
    if (_encryptionKey == null || _iv == null) {
      debugPrint('EncryptionService non initialisé');
      return plainText;
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Erreur chiffrement: $e');
      return plainText;
    }
  }

  /// Déchiffre une chaîne de caractères.
  ///
  /// Retourne la chaîne originale si le déchiffrement échoue
  /// (probablement des données non chiffrées).
  String? decryptString(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty) return encryptedText;
    if (_encryptionKey == null || _iv == null) {
      debugPrint('EncryptionService non initialisé');
      return encryptedText;
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // Probablement des données non chiffrées (migration)
      debugPrint('Erreur déchiffrement (données non chiffrées?): $e');
      return encryptedText;
    }
  }

  /// Chiffre des champs spécifiques d'un Map.
  ///
  /// [data] - Le map contenant les données.
  /// [sensitiveFields] - Liste des clés à chiffrer.
  /// [markAsEncrypted] - Ajouter un flag 'isEncrypted' au map résultant.
  Map<String, dynamic> encryptFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields, {
    bool markAsEncrypted = true,
  }) {
    final encrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encrypted[field] != null && encrypted[field] is String) {
        encrypted[field] = encryptString(encrypted[field] as String);
      }
    }

    if (markAsEncrypted) {
      encrypted['isEncrypted'] = true;
    }
    return encrypted;
  }

  /// Déchiffre des champs spécifiques d'un Map.
  ///
  /// Vérifie d'abord si le map est marqué comme chiffré.
  Map<String, dynamic> decryptFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields,
  ) {
    if (data['isEncrypted'] != true) return data;

    final decrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (decrypted[field] != null && decrypted[field] is String) {
        decrypted[field] = decryptString(decrypted[field] as String);
      }
    }

    return decrypted;
  }

  /// Supprime les clés stockées (à appeler lors de la déconnexion).
  Future<void> clearKeys(String userId) async {
    await _secureStorage.delete(key: '$_keyStorageKey:$userId');
    await _secureStorage.delete(key: '$_ivStorageKey:$userId');
    _encryptionKey = null;
    _iv = null;
  }

  /// Vérifie si le service est initialisé.
  bool get isInitialized => _encryptionKey != null && _iv != null;
}
