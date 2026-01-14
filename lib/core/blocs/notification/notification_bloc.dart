import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../firebase/smooth_firebase.dart';
import '../../models/base_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLoC pour la gestion des notifications.
///
/// Écoute les notifications en temps réel et gère leur état.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  StreamSubscription? _notificationsSubscription;
  String? _currentUserId;

  NotificationBloc() : super(const NotificationInitialState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<DeleteAllNotificationsEvent>(_onDeleteAllNotifications);
    on<NotificationsUpdatedEvent>(_onNotificationsUpdated);
  }

  /// Collection Firestore des notifications.
  String get _collectionPath => 'user_notifications';

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (_currentUserId == event.userId) return;

    _currentUserId = event.userId;
    emit(const NotificationLoadingState());

    // Annuler l'ancien stream
    await _notificationsSubscription?.cancel();

    // Écouter les notifications en temps réel
    _notificationsSubscription = SmoothFirebase.collection(_collectionPath)
        .where('userId', isEqualTo: event.userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final notifications = snapshot.docs
            .map((doc) => BaseNotification.fromMap(doc.data(), doc.id))
            .toList();

        add(NotificationsUpdatedEvent(notifications: notifications));
      },
      onError: (error) {
        emit(NotificationErrorState(message: 'Erreur: $error'));
      },
    );
  }

  void _onNotificationsUpdated(
    NotificationsUpdatedEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationLoadedState(notifications: event.notifications));
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await SmoothFirebase.collection(_collectionPath)
          .doc(event.notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (_currentUserId == null) return;

    try {
      final batch = SmoothFirebase.firestore.batch();

      final unread = await SmoothFirebase.collection(_collectionPath)
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (_) {}
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await SmoothFirebase.collection(_collectionPath)
          .doc(event.notificationId)
          .delete();
    } catch (_) {}
  }

  Future<void> _onDeleteAllNotifications(
    DeleteAllNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (_currentUserId == null) return;

    try {
      final batch = SmoothFirebase.firestore.batch();

      final all = await SmoothFirebase.collection(_collectionPath)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      for (final doc in all.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (_) {}
  }

  /// Nettoie le BLoC lors de la déconnexion.
  void clear() {
    _notificationsSubscription?.cancel();
    _currentUserId = null;
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
