import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/smooth_firebase.dart';
import '../models/device_session.dart';

/// Informations sur l'appareil actuel.
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String? deviceModel;
  final DeviceType deviceType;
  final String? osVersion;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    this.deviceModel,
    required this.deviceType,
    this.osVersion,
  });
}

/// Informations de localisation IP.
class IpLocationInfo {
  final String? ipAddress;
  final String? city;
  final String? country;

  const IpLocationInfo({this.ipAddress, this.city, this.country});
}

/// Service de gestion des sessions d'appareils.
///
/// Permet de tracker les appareils connectés et de révoquer des sessions à distance.
class BaseDeviceSessionService {
  static const String _collection = 'device_sessions';
  static const String _sessionIdKey = 'current_session_id';
  static const String _deviceIdKey = 'device_id';

  CollectionReference<Map<String, dynamic>> get _sessions =>
      SmoothFirebase.collection(_collection);

  // ============ Device Info ============

  /// Récupère les informations de l'appareil actuel.
  static Future<DeviceInfo> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return DeviceInfo(
        deviceId: ios.identifierForVendor ?? 'unknown-ios',
        deviceName: ios.name,
        deviceModel: ios.utsname.machine,
        deviceType: DeviceType.ios,
        osVersion: 'iOS ${ios.systemVersion}',
      );
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return DeviceInfo(
        deviceId: android.id,
        deviceName: android.model,
        deviceModel: android.device,
        deviceType: DeviceType.android,
        osVersion: 'Android ${android.version.release}',
      );
    } else if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      return DeviceInfo(
        deviceId: 'web-${DateTime.now().millisecondsSinceEpoch}',
        deviceName: '${web.browserName.name} on ${web.platform}',
        deviceModel: web.userAgent,
        deviceType: DeviceType.web,
        osVersion: web.platform,
      );
    }

    return const DeviceInfo(
      deviceId: 'unknown',
      deviceName: 'Unknown Device',
      deviceType: DeviceType.unknown,
    );
  }

  /// Récupère l'ID de l'appareil sauvegardé localement.
  static Future<String> getStoredDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      final info = await getDeviceInfo();
      deviceId = info.deviceId;
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Récupère la localisation via IP.
  static Future<IpLocationInfo> getIpLocation() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return IpLocationInfo(
          ipAddress: data['query'],
          city: data['city'],
          country: data['country'],
        );
      }
    } catch (e) {
      debugPrint('Failed to get IP location: $e');
    }
    return const IpLocationInfo();
  }

  // ============ Session Management ============

  /// Stream des sessions actives pour un utilisateur.
  Stream<List<DeviceSession>> streamUserSessions(String userId) {
    return _sessions
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => DeviceSession.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid composite index requirement
          sessions.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
          return sessions;
        });
  }

  /// Récupère la session actuelle de l'appareil.
  Future<DeviceSession?> getCurrentSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionIdKey);

    if (sessionId == null) return null;

    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;

    return DeviceSession.fromMap(doc.data()!, doc.id);
  }

  /// Crée une nouvelle session pour l'appareil actuel.
  Future<DeviceSession> createSession({
    required String userId,
    String? fcmToken,
    String? appVersion,
  }) async {
    final deviceInfo = await getDeviceInfo();
    final location = await getIpLocation();
    final now = DateTime.now();

    // Vérifier si une session existe déjà pour ce device
    final existing = await _sessions
        .where('userId', isEqualTo: userId)
        .where('deviceId', isEqualTo: deviceInfo.deviceId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Mettre à jour la session existante
      final existingSession =
          DeviceSession.fromMap(existing.docs.first.data(), existing.docs.first.id);
      await updateLastActive(existingSession.id, fcmToken: fcmToken);
      return existingSession.copyWith(lastActiveAt: now, fcmToken: fcmToken);
    }

    // Créer une nouvelle session
    final session = DeviceSession(
      id: '',
      userId: userId,
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      deviceModel: deviceInfo.deviceModel,
      deviceType: deviceInfo.deviceType,
      osVersion: deviceInfo.osVersion,
      appVersion: appVersion,
      fcmToken: fcmToken,
      ipAddress: location.ipAddress,
      city: location.city,
      country: location.country,
      loginAt: now,
      lastActiveAt: now,
      isActive: true,
    );

    final docRef = await _sessions.add(session.toMap());

    // Sauvegarder l'ID de session localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, docRef.id);

    return session.copyWith(id: docRef.id);
  }

  /// Met à jour la dernière activité de la session.
  Future<void> updateLastActive(String sessionId, {String? fcmToken}) async {
    final updates = <String, dynamic>{
      'lastActiveAt': FieldValue.serverTimestamp(),
    };
    if (fcmToken != null) {
      updates['fcmToken'] = fcmToken;
    }
    await _sessions.doc(sessionId).update(updates);
  }

  /// Révoque une session (déconnexion à distance).
  Future<void> revokeSession(String sessionId) async {
    await _sessions.doc(sessionId).update({'isActive': false});
  }

  /// Révoque toutes les autres sessions sauf celle actuelle.
  Future<void> revokeAllOtherSessions(String userId, String currentDeviceId) async {
    final sessions = await _sessions
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = SmoothFirebase.firestore.batch();
    for (final doc in sessions.docs) {
      if (doc.data()['deviceId'] != currentDeviceId) {
        batch.update(doc.reference, {'isActive': false});
      }
    }
    await batch.commit();
  }

  /// Révoque toutes les sessions d'un utilisateur.
  Future<void> revokeAllSessions(String userId) async {
    final sessions = await _sessions
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = SmoothFirebase.firestore.batch();
    for (final doc in sessions.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
  }

  /// Nettoie les sessions inactives anciennes.
  Future<void> cleanOldSessions(String userId, {Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final oldSessions = await _sessions
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: false)
        .where('lastActiveAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    final batch = SmoothFirebase.firestore.batch();
    for (final doc in oldSessions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Stream pour surveiller si la session actuelle est révoquée.
  Stream<bool> watchSessionRevoked(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snapshot) {
      if (!snapshot.exists) return true;
      return snapshot.data()?['isActive'] != true;
    });
  }

  /// Efface l'ID de session local (à appeler lors du logout).
  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
  }

  /// Récupère l'ID de la session locale.
  Future<String?> getLocalSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey);
  }
}
