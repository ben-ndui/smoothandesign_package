import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../firebase/smooth_firebase.dart';

/// Callback pour les messages en background.
/// Doit être une fonction top-level (pas dans une classe).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() doit être appelé si nécessaire
  debugPrint('Background message: ${message.messageId}');
}

/// Service de notifications push (FCM) et locales.
///
/// Pour utiliser:
/// 1. Initialiser dans main.dart après Firebase.initializeApp()
/// 2. Configurer les handlers de messages
/// 3. Demander les permissions
class BaseNotificationService {
  static BaseNotificationService? _instance;

  BaseNotificationService._();

  /// Singleton instance.
  static BaseNotificationService get instance {
    _instance ??= BaseNotificationService._();
    return _instance!;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Token FCM actuel.
  String? get fcmToken => _fcmToken;

  /// Indique si le service est initialisé.
  bool get isInitialized => _isInitialized;

  /// Initialise le service de notifications.
  ///
  /// [onSelectNotification] - Callback quand l'utilisateur tap une notification
  /// [onMessage] - Callback pour les messages reçus en foreground
  /// [androidChannelId] - ID du canal Android
  /// [androidChannelName] - Nom du canal Android
  Future<void> initialize({
    void Function(NotificationResponse)? onSelectNotification,
    void Function(RemoteMessage)? onMessage,
    String androidChannelId = 'default_channel',
    String androidChannelName = 'Notifications',
  }) async {
    if (_isInitialized) return;

    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // Créer le canal Android (requis pour Android 8+)
    final androidChannel = AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Configurer FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message, androidChannelId);
      onMessage?.call(message);
    });

    // Récupérer le token FCM
    await _refreshToken();

    // Écouter les refresh de token
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _onTokenRefresh(token);
    });

    _isInitialized = true;
  }

  /// Demande les permissions de notification.
  /// Retourne true si autorisé.
  Future<bool> requestPermissions() async {
    // iOS/macOS
    final settings = await SmoothFirebase.messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Vérifie si les permissions sont accordées.
  Future<bool> hasPermissions() async {
    final settings = await SmoothFirebase.messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Affiche une notification locale.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'Notifications',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// S'abonne à un topic FCM.
  Future<void> subscribeToTopic(String topic) async {
    await SmoothFirebase.messaging.subscribeToTopic(topic);
  }

  /// Se désabonne d'un topic FCM.
  Future<void> unsubscribeFromTopic(String topic) async {
    await SmoothFirebase.messaging.unsubscribeFromTopic(topic);
  }

  /// Annule une notification par ID.
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Annule toutes les notifications.
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Récupère le message initial (app lancée via notification).
  Future<RemoteMessage?> getInitialMessage() async {
    return await SmoothFirebase.messaging.getInitialMessage();
  }

  /// Configure le handler pour les notifications tapées (app en background).
  void onMessageOpenedApp(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  Future<void> _refreshToken() async {
    try {
      _fcmToken = await SmoothFirebase.messaging.getToken();
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message, String channelId) {
    final notification = message.notification;
    if (notification == null) return;

    showNotification(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data.toString(),
      channelId: channelId,
    );
  }

  /// Override pour gérer le refresh de token.
  /// Par défaut, ne fait rien. Surcharger pour sauvegarder le token.
  void _onTokenRefresh(String token) {
    // Override dans la sous-classe pour sauvegarder le token
  }
}
